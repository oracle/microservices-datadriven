"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Full build pipeline orchestrator.

Execution order:
  0. ddl        — CREATE TABLE statements from the schema's SQL DDL file (run as SCHEMARAG)
  1. seed       — populate schema tables with seed data
  2. sts        — execute workload queries, load SQL Tuning Set
  3. extract    — extract join co-occurrences → NODES / EDGES tables
  4. community  — Louvain community detection → update NODES table
  5. joinpaths  — extract multi-hop chains → JOIN_PATHS table
  6. annotate   — build metadata + annotations for all tables

Each step is idempotent: re-running updates rather than duplicating.

Note: OCI GenAI embedding (DBMS_VECTOR_CHAIN) is intentionally excluded from this
pipeline. NL2SQL uses two-step Claude retrieval (Haiku selects tables, Opus generates
SQL) — no vector search is required. Embedding is a future enhancement for the
vector space visualisation page in the Streamlit app.

Usage:
    # Full pipeline
    python -m src.pipeline.build_pipeline

    # Incremental steps
    python -m src.pipeline.build_pipeline --step ddl
    python -m src.pipeline.build_pipeline --step seed
    python -m src.pipeline.build_pipeline --step sts
    python -m src.pipeline.build_pipeline --step extract
    python -m src.pipeline.build_pipeline --step community
    python -m src.pipeline.build_pipeline --step joinpaths
    python -m src.pipeline.build_pipeline --step annotate

    # Coarse skips
    python -m src.pipeline.build_pipeline --skip-seed
    python -m src.pipeline.build_pipeline --skip-workload
"""
from __future__ import annotations

import argparse
import time

from rich.console import Console

from src.db.connection import get_connection, reset_pool
from src.schemas.base import SchemaContext, get_plugin

console = Console()

STEPS = ["user", "ddl", "seed", "sts", "extract", "community", "joinpaths", "annotate"]


def _step(label: str, fn, *args, **kwargs):
    console.rule(f"[bold magenta]{label}")
    t0 = time.time()
    fn(*args, **kwargs)
    elapsed = time.time() - t0
    console.print(f"[dim]  ✓ {label} — {elapsed:.1f}s[/dim]\n")


def _run_create_user(ctx: SchemaContext):
    """
    Create the schema owner and grant required privileges. Connects as ADMIN.

    Idempotent: skips CREATE USER if the user already exists.
    All GRANTs are re-issued on every run (Oracle silently ignores duplicate grants).
    """
    from src.workload.sts_loader import _get_admin_connection
    from src.config import settings

    schema = ctx.schema_name.upper()
    password = settings.adb_password

    grants = [
        f"GRANT CONNECT, RESOURCE TO {schema}",
        f"GRANT UNLIMITED TABLESPACE TO {schema}",
        f"GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO {schema}",
        f"GRANT CREATE PROCEDURE, CREATE TRIGGER TO {schema}",
        f"GRANT SELECT_CATALOG_ROLE TO {schema}",
        f"GRANT EXECUTE ON dbms_sqltune TO {schema}",
        f"GRANT EXECUTE ON dbms_xplan TO {schema}",
        f"GRANT ADMINISTER SQL TUNING SET TO {schema}",
    ]

    conn = _get_admin_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT DB_UNIQUE_NAME FROM V$DATABASE")
            (db_name,) = cur.fetchone()
            console.print(f"[dim]  Connected to database: {db_name}[/dim]")

            cur.execute(
                "SELECT COUNT(*) FROM dba_users WHERE username = :1", [schema]
            )
            (count,) = cur.fetchone()
            if count == 0:
                cur.execute(f'CREATE USER {schema} IDENTIFIED BY "{password}"')
                console.print(f"[green]  Created user {schema}[/green]")
            else:
                console.print(f"[yellow]  User {schema} already exists — skipping CREATE USER[/yellow]")

            for grant in grants:
                try:
                    cur.execute(grant)
                    console.print(f"[dim]  ✓ {grant}[/dim]")
                except Exception as exc:  # noqa: BLE001
                    console.print(f"[yellow]  SKIP[/yellow] {grant} — {exc!s:.80}")

            # Enable REST / Database Actions console access for this schema.
            # ORDS_ADMIN.ENABLE_SCHEMA must run as ADMIN; it is idempotent.
            cur.callproc("ORDS_ADMIN.ENABLE_SCHEMA", keywordParameters={
                "p_enabled": True,
                "p_schema": schema,
                "p_url_mapping_type": "BASE_PATH",
                "p_url_mapping_pattern": schema.lower(),
                "p_auto_rest_auth": True,
            })
            console.print(f"[dim]  ✓ ORDS REST access enabled for {schema}[/dim]")

        conn.commit()
    finally:
        conn.close()


def _split_sql(sql_text: str) -> list[str]:
    """
    Split SQL into individual statements on ';', correctly handling:
      - Single-quoted string literals  — ';' inside 'text; more' is not a delimiter
      - Escaped quotes ''              — stay in string mode
      - Line comments  --             — ';' inside a -- comment is not a delimiter;
                                        comment text is dropped (not sent to Oracle)
    """
    statements: list[str] = []
    buf: list[str] = []
    in_string = False
    in_comment = False
    i = 0
    while i < len(sql_text):
        ch = sql_text[i]

        if in_comment:
            # Skip everything until end of line; don't add to buf
            if ch == "\n":
                in_comment = False
            i += 1
            continue

        if in_string:
            buf.append(ch)
            if ch == "'":
                # '' is an escaped single quote — stay in string mode
                if i + 1 < len(sql_text) and sql_text[i + 1] == "'":
                    buf.append("'")
                    i += 2
                    continue
                in_string = False
        else:
            # Check for start of -- line comment
            if ch == "-" and i + 1 < len(sql_text) and sql_text[i + 1] == "-":
                in_comment = True
                i += 2
                continue
            if ch == "'":
                in_string = True
                buf.append(ch)
            elif ch == ";":
                clean = "".join(buf).strip()
                if clean:
                    statements.append(clean)
                buf = []
            else:
                buf.append(ch)
        i += 1

    # Trailing content after the last ';' (or files with no trailing semicolon)
    clean = "".join(buf).strip()
    if clean:
        statements.append(clean)
    return statements


def _run_ddl(ctx: SchemaContext):
    """
    Execute the schema's DDL SQL file using the SCHEMARAG connection.

    Uses _split_sql() which handles both string-literal semicolons and
    -- line-comment semicolons, and strips comment text before execution
    so oracledb's bind-variable scanner never misinterprets quotes in comments.

    Already-existing tables are silently skipped (ORA-00955).
    """
    from pathlib import Path

    _PROJECT_ROOT = Path(__file__).resolve().parents[2]

    workload_path = Path(ctx.workload_sql_path)
    ddl_path = _PROJECT_ROOT / workload_path.parent / "01_create_schema.sql"

    if not ddl_path.exists():
        raise FileNotFoundError(f"DDL file not found: {ddl_path}")

    statements = _split_sql(ddl_path.read_text(encoding="utf-8"))

    tables_created = tables_skipped = comments_ok = comments_skipped = 0
    with get_connection() as conn:
        with conn.cursor() as cur:
            for clean in statements:
                upper = clean.upper().lstrip()
                is_table = upper.startswith("CREATE TABLE")
                is_comment = upper.startswith("COMMENT")
                try:
                    cur.execute(clean)
                    if is_table:
                        tables_created += 1
                    elif is_comment:
                        comments_ok += 1
                except Exception as exc:  # noqa: BLE001
                    err = str(exc).splitlines()[0]
                    # ORA-00955: object already exists — expected on re-runs
                    if "ORA-00955" in err:
                        if is_table:
                            tables_skipped += 1
                    else:
                        first_line = clean.splitlines()[0][:80]
                        console.print(f"[yellow]  SKIP[/yellow] [{first_line}] {err[:100]}")
                        if is_comment:
                            comments_skipped += 1
        conn.commit()

    console.print(
        f"DDL complete — "
        f"tables: [green]{tables_created} created[/green] / [yellow]{tables_skipped} already existed[/yellow]  |  "
        f"comments: [green]{comments_ok} ok[/green] / [yellow]{comments_skipped} skipped[/yellow]"
    )


def _run_seed(plugin):
    _step("Step 1 — Seed Data", plugin.run_seed)


def _run_sts(plugin):
    _step("Step 2 — STS Loader (workload queries)", plugin.run_workload)


def _run_extract(ctx: SchemaContext):
    from src.workload.sts_extractor import extract_affinities
    _step("Step 3 — STS Extractor (join co-occurrence)", extract_affinities, ctx)


def _run_community(ctx: SchemaContext):
    from src.graph.graph_builder import load_graph
    from src.graph.community_detector import detect_communities, run_community_detection
    from src.graph.community_namer import name_communities
    G = load_graph(ctx, include_excluded=True)
    partition = detect_communities(G)
    names = name_communities(partition)
    _step("Step 4 — Community Detection (Louvain)", run_community_detection, ctx, community_names=names)


def _run_joinpaths(ctx: SchemaContext):
    from src.graph.join_path_extractor import extract_join_paths
    _step("Step 5 — Join-Path Extraction", extract_join_paths, ctx)


def _run_annotate(ctx: SchemaContext):
    from src.annotations.metadata_augmentor import augment_all_tables
    _step("Step 6 — Metadata Augmentation (all 4 annotation types)", augment_all_tables, ctx)


def run_build(
    plugin,
    skip_seed: bool = False,
    skip_workload: bool = False,
) -> None:
    ctx = plugin.context
    console.print(f"[bold]Schema:[/bold] {ctx.schema_name} — {ctx.schema_description}\n")

    if not skip_seed:
        _run_seed(plugin)
    if not skip_workload:
        _run_sts(plugin)
        _run_extract(ctx)
        _run_community(ctx)
        _run_joinpaths(ctx)
    _run_annotate(ctx)
    console.rule("[bold green]Build Pipeline Complete")


if __name__ == "__main__":
    # Import plugin to populate the registry before parsing --schema
    import src.schemas.university.plugin  # noqa: F401

    parser = argparse.ArgumentParser(description="Run the SchemaRAG build pipeline")
    parser.add_argument(
        "--schema", default="university",
        help="Schema to build (default: university)"
    )
    parser.add_argument("--skip-seed", action="store_true", help="Skip seeding (data already loaded)")
    parser.add_argument("--skip-workload", action="store_true", help="Skip STS/graph steps (re-annotate only)")
    parser.add_argument("--step", choices=STEPS, metavar="STEP",
                        help=f"Run a single step: {', '.join(STEPS)}")
    args = parser.parse_args()

    plugin = get_plugin(args.schema)
    ctx = plugin.context

    # Ensure all get_connection() calls in this process connect as the schema user,
    # not the global ADB_USER from .env (which may differ across schemas).
    reset_pool(ctx.schema_name)
    console.print(f"[dim]Connection pool initialized as: {ctx.schema_name}[/dim]")

    step_fns = {
        "user":      lambda: _step("Step 0a — Create User + Grants (ADMIN)", _run_create_user, ctx),
        "ddl":       lambda: _step("Step 0b — DDL (CREATE TABLEs)", _run_ddl, ctx),
        "seed":      lambda: _run_seed(plugin),
        "sts":       lambda: _run_sts(plugin),
        "extract":   lambda: _run_extract(ctx),
        "community": lambda: _run_community(ctx),
        "joinpaths": lambda: _run_joinpaths(ctx),
        "annotate":  lambda: _run_annotate(ctx),
    }

    if args.step:
        step_fns[args.step]()
        console.rule(f"[bold green]Step '{args.step}' complete")
    else:
        run_build(plugin, skip_seed=args.skip_seed, skip_workload=args.skip_workload)
