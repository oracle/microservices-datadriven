"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Execute the workload queries from a schema's SQL file against ADB,
using high-volume server-side loops to simulate a realistic production workload.
Then load the resulting cursor-cache entries into the schema's SQL Tuning Set.

Usage:
    python -m src.workload.sts_loader
"""
from __future__ import annotations

import re
import time
from pathlib import Path

import oracledb
from rich.console import Console
from rich.progress import track

from src.db.connection import get_connection
from src.schemas.base import SchemaContext

console = Console()

_PROJECT_ROOT = Path(__file__).resolve().parents[2]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _create_sts_if_needed(sts_name: str, sts_description: str) -> None:
    """Create the SQL Tuning Set if it does not already exist."""
    check_sql = """
        SELECT COUNT(*)
        FROM user_sqlset
        WHERE name = :name
    """
    create_plsql = f"""
        BEGIN
            DBMS_SQLTUNE.CREATE_SQLSET(
                sqlset_name => '{sts_name}',
                description => '{sts_description}'
            );
        END;
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(check_sql, name=sts_name)
            (count,) = cur.fetchone()
            if count == 0:
                cur.execute(create_plsql)
                console.print(f"[green]Created SQL Tuning Set:[/green] {sts_name}")
            else:
                console.print(f"[yellow]SQL Tuning Set already exists:[/yellow] {sts_name}")


def _execute_workload_queries(query_weights: list[tuple[str, int]]) -> None:
    """
    Execute queries using server-side PL/SQL loops to generate high execution counts.
    """
    ok = err = 0

    plsql_wrapper = """
        BEGIN
            FOR i IN 1..:weight LOOP
                DECLARE
                    c SYS_REFCURSOR;
                BEGIN
                    OPEN c FOR :sql;
                    CLOSE c;
                EXCEPTION WHEN OTHERS THEN
                    NULL;
                END;
            END LOOP;
        END;
    """

    with get_connection() as conn:
        for stmt, weight in track(query_weights, description="Generating high-volume workload…"):
            try:
                with conn.cursor() as cur:
                    cur.execute(plsql_wrapper, weight=weight, sql=stmt)
                ok += 1
            except Exception as exc:  # noqa: BLE001
                err += 1
                if err < 5:
                    console.print(f"[red]  WARN[/red] {exc!s:.120}")
    console.print(f"Queries processed — ok={ok}  errors={err}")


def _get_admin_connection():
    """Return a standalone admin connection for privileged STS operations."""
    from src.config import settings
    kwargs: dict = dict(
        user=settings.adb_admin_user,
        password=settings.adb_admin_password,
        dsn=settings.adb_dsn,
    )
    if settings.adb_wallet_location:
        kwargs["config_dir"] = str(settings.wallet_path)
        kwargs["wallet_location"] = str(settings.wallet_path)
        if settings.adb_wallet_password:
            kwargs["wallet_password"] = settings.adb_wallet_password
    return oracledb.connect(**kwargs)


def _load_sts_from_cursor_cache(ctx: SchemaContext) -> int:
    """
    Bulk-load cursor-cache entries into the STS. Must run as ADMIN.
    """
    schema_name = ctx.schema_name.upper()
    sts_name = ctx.sts_name
    sts_desc = ctx.sts_description

    load_plsql = f"""
        DECLARE
            cur DBMS_SQLTUNE.SQLSET_CURSOR;
        BEGIN
            BEGIN
                DBMS_SQLTUNE.DROP_SQLSET(sqlset_name => '{sts_name}', sqlset_owner => '{schema_name}');
            EXCEPTION WHEN OTHERS THEN NULL;
            END;

            DBMS_SQLTUNE.CREATE_SQLSET(sqlset_name => '{sts_name}', description => '{sts_desc}', sqlset_owner => '{schema_name}');

            OPEN cur FOR
                SELECT VALUE(p)
                FROM TABLE(
                    DBMS_SQLTUNE.SELECT_CURSOR_CACHE(
                        'parsing_schema_name = ''{schema_name}'' AND upper(sql_text) LIKE ''SELECT %''',
                        NULL, NULL, NULL, NULL, 1, NULL,
                        'ALL', 'ALL'
                    )
                ) p;
            DBMS_SQLTUNE.LOAD_SQLSET(
                sqlset_name     => '{sts_name}',
                populate_cursor => cur,
                sqlset_owner    => '{schema_name}'
            );
            CLOSE cur;
        END;
    """
    count_sql = f"""
        SELECT COUNT(*)
        FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET(
            sqlset_name  => '{sts_name}',
            sqlset_owner => '{schema_name}'
        ))
    """
    conn = _get_admin_connection()
    try:
        # ── Diagnostic: how many entries are visible in the cursor cache? ──────
        with conn.cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) FROM v$sql WHERE parsing_schema_name = :1",
                [schema_name],
            )
            (vsql_total,) = cur.fetchone()
            cur.execute(
                "SELECT COUNT(*) FROM v$sql "
                "WHERE parsing_schema_name = :1 AND upper(sql_text) LIKE 'SELECT %'",
                [schema_name],
            )
            (vsql_select,) = cur.fetchone()
        console.print(
            f"[dim]Cursor cache (V$SQL) for {schema_name}: "
            f"{vsql_total} total statements, {vsql_select} SELECT statements[/dim]"
        )
        if vsql_select == 0:
            console.print(
                "[yellow]WARNING: no SELECT statements found in cursor cache for "
                f"{schema_name} — workload may not have populated the cache. "
                "Check that UNIV_SCHEMARAG can SELECT from its own tables.[/yellow]"
            )
        # ── Load STS ──────────────────────────────────────────────────────────
        with conn.cursor() as cur:
            cur.execute(load_plsql)
            conn.commit()
        with conn.cursor() as cur:
            cur.execute(count_sql)
            (count,) = cur.fetchone()
    finally:
        conn.close()
    return count


def load_workload(ctx: SchemaContext) -> None:
    """Full pipeline: execute workload queries → load STS from cursor cache."""
    console.rule("[bold cyan]High-Volume STS Loader")

    workload_sql = _PROJECT_ROOT / ctx.workload_sql_path
    if not workload_sql.exists():
        raise FileNotFoundError(f"Workload SQL not found: {workload_sql}")

    raw_text = workload_sql.read_text(encoding="utf-8")
    raw_statements = [s.strip() for s in raw_text.split(";") if s.strip()]

    query_weights = []
    total_est = 0
    current_weight = 10  # default weight until a FAMILY header is seen

    for stmt in raw_statements:
        # Update weight when we encounter a FAMILY section header comment.
        # Two detection strategies (tried in order):
        #   1. Affinity-level keyword in the header (works for ERP and any schema
        #      that labels families as "HIGH affinity", "MEDIUM affinity", etc.)
        #   2. Family-letter fallback for workload SQL that
        #      uses labelled families A/B/G/H without affinity-level keywords.
        if "FAMILY" in stmt:
            upper = stmt.upper()
            if "HIGH AFFINITY" in upper:
                current_weight = 1500
            elif "MEDIUM AFFINITY" in upper or "MULTI-HOP" in upper:
                current_weight = 400
            elif "LOW AFFINITY" in upper:
                current_weight = 200
            elif "FAMILY A" in stmt:
                current_weight = 1500
            elif "FAMILY B" in stmt:
                current_weight = 800
            elif "FAMILY G" in stmt or "FAMILY H" in stmt:
                current_weight = 400

        weight = current_weight

        clean_stmt = re.sub(r"--[^\n]*", "", stmt).strip()
        if clean_stmt:
            query_weights.append((clean_stmt, weight))
            total_est += weight

    console.print(f"Parsed [bold]{len(raw_statements)}[/bold] distinct queries.")
    console.print(f"Simulating [bold]{total_est:,}[/bold] total executions (High-Volume Mode).")

    _create_sts_if_needed(ctx.sts_name, ctx.sts_description)

    console.print("\n[bold]Step 1/2[/bold] — Running server-side workload loops…")
    _execute_workload_queries(query_weights)

    time.sleep(2)

    console.print("\n[bold]Step 2/2[/bold] — Loading STS from cursor cache…")
    count = _load_sts_from_cursor_cache(ctx)
    console.print(f"[green]STS loaded — {count} SQL statements in {ctx.sts_name}[/green]")


if __name__ == "__main__":
    import argparse
    import src.schemas.university.plugin  # noqa: F401
    from src.schemas.base import get_plugin

    parser = argparse.ArgumentParser(description="Load workload queries into STS")
    parser.add_argument("--schema", default="university", help="Schema to use (default: university)")
    args = parser.parse_args()

    ctx = get_plugin(args.schema).context
    load_workload(ctx)
