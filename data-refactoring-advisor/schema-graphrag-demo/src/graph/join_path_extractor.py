# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Extract multi-hop join-path chains from the SQL Tuning Set.

A join-path chain is an ordered sequence of schema tables that appear
together in a single SQL statement's FROM/JOIN clause, forming a logical
traversal path (e.g. STU_MST→ENRL_REC→GRD_HIST).

Patent Claim 1 requires JOINS_PATH annotations — this module produces them.

Algorithm
---------
1. Parse every STS statement with sqlglot.
2. Identify the query's table list (ordered by first appearance in the AST).
3. Emit every sub-path of length ≥ 3 as a candidate chain.
4. Aggregate: count how many distinct SQL IDs contain each chain.
5. Keep chains with occurrence_count ≥ MIN_OCCURRENCE.
6. Persist to the schema's JOIN_PATHS table.

Usage:
    python -m src.graph.join_path_extractor
"""
from __future__ import annotations

import itertools
from collections import defaultdict

import sqlglot
from rich.console import Console
from rich.progress import track

from src.db.connection import get_connection
from src.schemas.base import SchemaContext
from src.workload.sts_extractor import fetch_sts_rows

console = Console()

# Minimum number of distinct SQL statements a chain must appear in
MIN_OCCURRENCE = 2
# Minimum chain length (number of tables)
MIN_HOP_COUNT = 3


# ---------------------------------------------------------------------------
# Parse ordered table list from a SQL statement
# ---------------------------------------------------------------------------

def _ordered_tables(
    sql_text: str,
    schema_name: str,
    table_names: frozenset[str],
) -> list[str]:
    """
    Return schema tables in the order they appear in the SQL AST
    (depth-first traversal). Duplicates removed while preserving order.
    """
    seen: set[str] = set()
    ordered: list[str] = []
    try:
        for stmt in sqlglot.parse(sql_text, dialect="oracle"):
            if stmt is None:
                continue
            for tbl in stmt.find_all(sqlglot.exp.Table):
                # Use the .db / .catalog string properties, not .args.get() which
                # returns an Identifier object — calling .upper() on that raises
                # AttributeError and silently empties the result via the except below.
                db = tbl.db or tbl.catalog  # "" when no schema qualifier present
                name = tbl.name
                if not name:
                    continue
                if not db or db.upper() == schema_name.upper():
                    up = name.upper()
                    if up in table_names and up not in seen:
                        seen.add(up)
                        ordered.append(up)
    except Exception:  # noqa: BLE001
        pass
    return ordered


# ---------------------------------------------------------------------------
# Chain enumeration
# ---------------------------------------------------------------------------

def _subpaths(tables: list[str], min_len: int = MIN_HOP_COUNT) -> list[tuple[str, ...]]:
    """Enumerate all contiguous sub-sequences of length >= min_len."""
    paths = []
    n = len(tables)
    for start in range(n):
        for end in range(start + min_len, n + 1):
            paths.append(tuple(tables[start:end]))
    return paths


# ---------------------------------------------------------------------------
# Build chain occurrence counts
# ---------------------------------------------------------------------------

def build_chain_counts(
    rows: list,  # list[StsRow]
    schema_name: str,
    table_names: frozenset[str],
) -> dict[tuple[str, ...], int]:
    """
    Return a dict: chain_tuple → count of distinct SQL IDs containing it.
    Only includes chains of length >= MIN_HOP_COUNT.
    """
    chain_sql_ids: dict[tuple[str, ...], set[str]] = defaultdict(set)

    for row in track(rows, description="Extracting join-path chains…"):
        tables = _ordered_tables(row.sql_text, schema_name, table_names)
        if len(tables) < MIN_HOP_COUNT:
            continue
        for chain in _subpaths(tables, MIN_HOP_COUNT):
            chain_sql_ids[chain].add(row.sql_id)

    return {chain: len(sql_ids) for chain, sql_ids in chain_sql_ids.items()}


# ---------------------------------------------------------------------------
# Community span
# ---------------------------------------------------------------------------

def _get_community_map(nodes_table: str) -> dict[str, str]:
    """Fetch table_name → community_name from the NODES table."""
    sql = f"SELECT table_name, community_name FROM {nodes_table} WHERE community_name IS NOT NULL"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            return {row[0]: row[1] for row in cur.fetchall()}


def _community_span(chain: tuple[str, ...], community_map: dict[str, str]) -> int:
    """Number of distinct communities touched by this chain."""
    communities = {community_map.get(tbl, "Unknown") for tbl in chain}
    return len(communities)


# ---------------------------------------------------------------------------
# Persist
# ---------------------------------------------------------------------------

def _persist_chains(
    chain_counts: dict[tuple[str, ...], int],
    community_map: dict[str, str],
    join_paths_table: str,
) -> int:
    """Upsert qualifying chains into the JOIN_PATHS table. Returns row count."""
    qualifying = {
        chain: count
        for chain, count in chain_counts.items()
        if count >= MIN_OCCURRENCE
    }

    if not qualifying:
        console.print("[yellow]No chains met the minimum occurrence threshold.[/yellow]")
        return 0

    insert_sql = f"""
        INSERT INTO {join_paths_table}
            (anchor_table, table_sequence, hop_count, occurrence_count, community_span)
        VALUES (:anchor, :seq, :hops, :occ, :cspan)
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(f"DELETE FROM {join_paths_table}")

    rows = []
    for chain, count in qualifying.items():
        rows.append(dict(
            anchor=chain[0],
            seq="→".join(chain),
            hops=len(chain),
            occ=count,
            cspan=_community_span(chain, community_map),
        ))

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.executemany(insert_sql, rows)

    return len(rows)


# ---------------------------------------------------------------------------
# Public entry points
# ---------------------------------------------------------------------------

def extract_join_paths(ctx: SchemaContext) -> None:
    """Full pipeline: fetch STS → parse chains → persist."""
    console.rule("[bold cyan]Join-Path Extractor")

    rows = fetch_sts_rows(ctx.sts_name)
    if not rows:
        console.print("[red]No STS rows found — run sts_loader first.[/red]")
        return

    chain_counts = build_chain_counts(rows, ctx.schema_name, ctx.table_names)
    console.print(
        f"Found [bold]{len(chain_counts)}[/bold] unique chains  "
        f"(threshold ≥ {MIN_OCCURRENCE} occurrences)"
    )

    community_map = _get_community_map(ctx.nodes_table)
    persisted = _persist_chains(chain_counts, community_map, ctx.join_paths_table)
    console.print(f"[green]Persisted [bold]{persisted}[/bold] join-path chains → {ctx.join_paths_table}[/green]")

    top = sorted(chain_counts.items(), key=lambda x: -x[1])[:5]
    if top:
        console.print("\nTop 5 most common chains:")
        for chain, count in top:
            console.print(f"  {count:>4}×  {'→'.join(chain)}")


def get_paths_for_table(anchor_table: str, join_paths_table: str) -> list[str]:
    """
    Retrieve all join-path chain strings that include `anchor_table` anywhere
    in the sequence (not just as the first-hop anchor).
    Used by annotation_generator.

    Match strategy: wrap table_sequence with '→' on both ends so every table
    position is delimited consistently, then LIKE-match '→TABLE→'.
    """
    sql = f"""
        SELECT table_sequence
        FROM {join_paths_table}
        WHERE ('→' || table_sequence || '→') LIKE ('%→' || :tbl || '→%')
        ORDER BY occurrence_count DESC
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tbl=anchor_table.upper())
            return [row[0] for row in cur.fetchall()]


if __name__ == "__main__":
    import argparse
    import src.schemas.university.plugin  # noqa: F401
    from src.schemas.base import get_plugin

    parser = argparse.ArgumentParser(description="Extract join path chains from STS")
    parser.add_argument("--schema", default="university", help="Schema to use (default: university)")
    args = parser.parse_args()

    ctx = get_plugin(args.schema).context
    extract_join_paths(ctx)
