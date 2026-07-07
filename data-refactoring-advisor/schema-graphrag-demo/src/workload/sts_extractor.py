# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Extract join co-occurrence data from a SQL Tuning Set and persist results
to the schema's NODES and EDGES tables.

Algorithm
---------
1.  For every SQL statement in the STS, parse the SQL text with sqlglot to find
    all table references in FROM / JOIN clauses that belong to the target schema.
2.  For each pair of tables that appear in the same statement, record:
        - join_count      : distinct SQL IDs containing both tables
        - join_executions : sum of executions across those SQL IDs
3.  Per-table totals (sql_count, exec_count) feed the affinity denominator.
4.  Compute affinity via affinity_calculator, write rows to NODES / EDGES
    (upsert semantics).

Usage:
    python -m src.workload.sts_extractor
"""
from __future__ import annotations

import itertools
import re
from collections import defaultdict
from typing import NamedTuple

import sqlglot
from rich.console import Console
from rich.progress import track

from src.db.connection import get_connection
from src.schemas.base import SchemaContext
from src.workload.affinity_calculator import build_affinity_result

console = Console()


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

class StsRow(NamedTuple):
    sql_id: str
    sql_text: str
    executions: int


# ---------------------------------------------------------------------------
# Step 1 — Fetch SQL statements from STS
# ---------------------------------------------------------------------------

def fetch_sts_rows(sts_name: str) -> list[StsRow]:
    """Pull all SQL statements from the named SQL Tuning Set."""
    sql = f"""
        SELECT s.sql_id,
               s.sql_text,
               NVL(s.executions, 1) AS executions
        FROM TABLE(DBMS_SQLTUNE.SELECT_SQLSET('{sts_name}')) s
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            rows = []
            for sql_id, sql_text, executions in cur.fetchall():
                rows.append(StsRow(
                    sql_id=str(sql_id),
                    sql_text=str(sql_text) if sql_text else "",
                    executions=int(executions or 1),
                ))
    console.print(f"Fetched [bold]{len(rows)}[/bold] SQL statements from {sts_name}")
    return rows




# ---------------------------------------------------------------------------
# Step 2 — Parse table references with sqlglot
# ---------------------------------------------------------------------------

def _extract_schema_tables(
    sql_text: str,
    schema_name: str,
    table_names: frozenset[str],
) -> set[str]:
    """
    Use sqlglot to parse a SQL statement and return the set of schema table
    names referenced (upper-cased, schema qualifier stripped).
    Falls back to a simple regex scan on parse failure.
    """
    tables: set[str] = set()
    try:
        for stmt in sqlglot.parse(sql_text, dialect="oracle"):
            if stmt is None:
                continue
            for tbl in stmt.find_all(sqlglot.exp.Table):
                db = tbl.args.get("db") or tbl.args.get("catalog")
                name = tbl.name
                if not name:
                    continue
                name_upper = name.upper()
                if name_upper in table_names and (
                    db is None or db.upper() == schema_name.upper()
                ):
                    tables.add(name_upper)
    except Exception:  # noqa: BLE001
        # Fallback: crude regex — still filter against whitelist
        import re
        pattern = rf"\b(?:FROM|JOIN)\s+(?:{re.escape(schema_name)}\.)?([A-Z_][A-Z0-9_]*)\b"
        for m in re.finditer(pattern, sql_text.upper()):
            name_upper = m.group(1)
            if name_upper in table_names:
                tables.add(name_upper)
    return tables


# ---------------------------------------------------------------------------
# Step 3 — Build co-occurrence accumulators
# ---------------------------------------------------------------------------

def build_cooccurrence(
    rows: list[StsRow],
    schema_name: str,
    table_names: frozenset[str],
) -> tuple[
    dict[str, int],              # table → distinct SQL count
    dict[str, int],              # table → total executions
    dict[tuple[str, str], int],  # pair → join_count (distinct SQLs)
    dict[tuple[str, str], int],  # pair → join_executions (total exec)
]:
    table_sql_count: dict[str, int] = defaultdict(int)
    table_exec_count: dict[str, int] = defaultdict(int)
    pair_join_count: dict[tuple[str, str], int] = defaultdict(int)
    pair_join_exec: dict[tuple[str, str], int] = defaultdict(int)

    for row in track(rows, description="Parsing SQL statements…"):
        tables = _extract_schema_tables(row.sql_text, schema_name, table_names)
        if not tables:
            continue

        for tbl in tables:
            table_sql_count[tbl] += 1
            table_exec_count[tbl] += row.executions

        for t1, t2 in itertools.combinations(sorted(tables), 2):
            key = (t1, t2)
            pair_join_count[key] += 1
            pair_join_exec[key] += row.executions

    return table_sql_count, table_exec_count, pair_join_count, pair_join_exec


# ---------------------------------------------------------------------------
# Step 4 — Persist to NODES and EDGES tables
# ---------------------------------------------------------------------------

def _upsert_nodes(
    table_sql_count: dict[str, int],
    table_exec_count: dict[str, int],
    nodes_table: str,
) -> None:
    sql = f"""
        MERGE INTO {nodes_table} t
        USING (SELECT :tbl AS table_name FROM dual) s
        ON (t.table_name = s.table_name)
        WHEN MATCHED THEN UPDATE SET
            access_frequency   = :sc,
            join_participation = :ec,
            updated_at         = SYSTIMESTAMP
        WHEN NOT MATCHED THEN INSERT
            (table_name, access_frequency, join_participation, created_at)
        VALUES (:tbl, :sc, :ec, SYSTIMESTAMP)
    """
    rows = [
        dict(tbl=tbl, sc=table_sql_count[tbl], ec=table_exec_count[tbl])
        for tbl in table_sql_count
    ]
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.executemany(sql, rows)
    console.print(f"Upserted [bold]{len(rows)}[/bold] rows → {nodes_table}")


def _upsert_edges(
    pair_join_count: dict[tuple[str, str], int],
    pair_join_exec: dict[tuple[str, str], int],
    table_sql_count: dict[str, int],
    table_exec_count: dict[str, int],
    edges_table: str,
) -> None:
    sql = f"""
        MERGE INTO {edges_table} t
        USING (SELECT :t1 AS table_name_1, :t2 AS table_name_2 FROM dual) s
        ON (t.table_name_1 = s.table_name_1 AND t.table_name_2 = s.table_name_2)
        WHEN MATCHED THEN UPDATE SET
            join_count          = :jc,
            join_executions     = :je,
            static_coefficient  = :sc,
            dynamic_coefficient = :dc,
            total_affinity      = :ta,
            affinity_level      = :al,
            updated_at          = SYSTIMESTAMP
        WHEN NOT MATCHED THEN INSERT
            (table_name_1, table_name_2, join_count, join_executions,
             static_coefficient, dynamic_coefficient, total_affinity, affinity_level, created_at)
        VALUES (:t1, :t2, :jc, :je, :sc, :dc, :ta, :al, SYSTIMESTAMP)
    """
    rows = []
    for (t1, t2), jc in pair_join_count.items():
        je = pair_join_exec[(t1, t2)]
        result = build_affinity_result(
            table1=t1, table2=t2,
            join_count=jc,
            join_executions=je,
            sql_t1=table_sql_count.get(t1, 1),
            sql_t2=table_sql_count.get(t2, 1),
            exec_t1=table_exec_count.get(t1, 1),
            exec_t2=table_exec_count.get(t2, 1),
        )
        rows.append(dict(
            t1=t1, t2=t2, jc=jc, je=je,
            sc=round(result.static_coeff, 6),
            dc=round(result.dynamic_coeff, 6),
            ta=round(result.total_affinity, 6),
            al=result.affinity_level,
        ))

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.executemany(sql, rows)

    by_level: dict[str, int] = defaultdict(int)
    for r in rows:
        by_level[r["al"]] += 1
    console.print(
        f"Upserted [bold]{len(rows)}[/bold] rows → {edges_table}  "
        f"(HIGH={by_level['HIGH']}  MEDIUM={by_level['MEDIUM']}  "
        f"LOW={by_level['LOW']}  EXCLUDED={by_level['EXCLUDED']})"
    )


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def extract_affinities(ctx: SchemaContext) -> None:
    """Full pipeline: fetch STS → parse → compute affinities → persist."""
    console.rule("[bold cyan]STS Extractor")

    rows = fetch_sts_rows(ctx.sts_name)
    if not rows:
        raise RuntimeError(
            f"STS '{ctx.sts_name}' is empty. "
            "Run --step sts before --step extract."
        )

    t_sql, t_exec, p_jc, p_je = build_cooccurrence(rows, ctx.schema_name, ctx.table_names)
    console.print(
        f"Found [bold]{len(t_sql)}[/bold] schema tables  "
        f"[bold]{len(p_jc)}[/bold] table pairs"
    )

    _upsert_nodes(t_sql, t_exec, ctx.nodes_table)
    _upsert_edges(p_jc, p_je, t_sql, t_exec, ctx.edges_table)

    console.print("[green]Affinity extraction complete.[/green]")


if __name__ == "__main__":
    import argparse
    import src.schemas.university.plugin  # noqa: F401
    from src.schemas.base import get_plugin

    parser = argparse.ArgumentParser(description="Extract affinities from STS")
    parser.add_argument("--schema", default="university", help="Schema to use (default: university)")
    args = parser.parse_args()

    ctx = get_plugin(args.schema).context
    extract_affinities(ctx)
