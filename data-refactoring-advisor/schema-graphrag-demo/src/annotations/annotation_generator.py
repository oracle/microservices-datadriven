"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Core invention: generate all 4 patent annotation types for a given table.

Annotation types (patent Claims 1, 5, 6, 7):
  1. Community membership  : [T IN_COMMUNITY Name]
  2. Hub indicator         : [T IS_HUB degree:N]
  3. Join indicators       : [T JOINS_WITH T2]
  4. Affinity indicators   : [T HIGH_AFFINITY T2:0.91]  (HIGH / MEDIUM / LOW)
  5. Bridge indicators     : [T BRIDGES Comm1:Comm2]
  6. Join-path chains      : [T JOINS_PATH T→T2→T3→T4]

Excluded relationships (affinity < 0.2) deliberately produce NO annotation —
demonstrating patent Claim 6's threshold enforcement.

Token budget: Cohere embed-english-v3.0 handles ~512 tokens.
For hub tables with many neighbours, LOW-affinity annotations are truncated last.

Usage (CLI spot-check):
    python -m src.annotations.annotation_generator --table ENCOUNTERS
    python -m src.annotations.annotation_generator --table BEDS
"""
from __future__ import annotations

import argparse
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Optional

from rich.console import Console

from src.db.connection import get_connection
from src.graph.join_path_extractor import get_paths_for_table
from src.schemas.base import SchemaContext

console = Console()

# Max annotations before we start truncating LOW-affinity lines
_TOKEN_BUDGET_LINES = 40


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

@dataclass
class EdgeInfo:
    other_table: str
    total_affinity: float
    affinity_level: str   # HIGH | MEDIUM | LOW | EXCLUDED


@dataclass
class NodeInfo:
    table_name: str
    community_name: str
    is_bridge: bool
    is_hub: bool
    hub_degree: float
    bridge_communities: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# DB reads
# ---------------------------------------------------------------------------

def _load_node_info(table_name: str, nodes_table: str) -> Optional[NodeInfo]:
    """Read community + bridge/hub flags from the NODES table."""
    sql = f"""
        SELECT table_name, community_name, is_bridge, is_hub, hub_degree
        FROM {nodes_table}
        WHERE table_name = :tbl
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tbl=table_name.upper())
            row = cur.fetchone()
    if row is None:
        return None
    tbl, cname, is_bridge, is_hub, hub_degree = row
    return NodeInfo(
        table_name=str(tbl),
        community_name=str(cname) if cname else "Unknown",
        is_bridge=bool(is_bridge),
        is_hub=bool(is_hub),
        hub_degree=float(hub_degree or 0.0),
    )


def _load_edges(table_name: str, edges_table: str) -> list[EdgeInfo]:
    """Read all edges for this table from the EDGES table (excluding EXCLUDED level)."""
    sql = f"""
        SELECT
            CASE WHEN table_name_1 = :tbl THEN table_name_2 ELSE table_name_1 END AS other_table,
            total_affinity,
            affinity_level
        FROM {edges_table}
        WHERE (table_name_1 = :tbl OR table_name_2 = :tbl)
          AND affinity_level <> 'EXCLUDED'
        ORDER BY total_affinity DESC
    """
    edges = []
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tbl=table_name.upper())
            for other, affinity, level in cur.fetchall():
                edges.append(EdgeInfo(
                    other_table=str(other),
                    total_affinity=float(affinity),
                    affinity_level=str(level),
                ))
    return edges


def _load_bridge_communities(
    table_name: str,
    nodes_table: str,
    edges_table: str,
) -> list[str]:
    """
    Return the distinct community names of this table's neighbours — used
    to build the BRIDGES annotation (only if is_bridge=True).
    """
    sql = f"""
        SELECT DISTINCT n.community_name
        FROM {nodes_table} n
        WHERE n.table_name IN (
            SELECT CASE WHEN e.table_name_1 = :tbl THEN e.table_name_2 ELSE e.table_name_1 END
            FROM {edges_table} e
            WHERE (e.table_name_1 = :tbl OR e.table_name_2 = :tbl)
              AND e.affinity_level <> 'EXCLUDED'
        )
          AND n.community_name IS NOT NULL
          AND n.community_name <> (
              SELECT community_name FROM {nodes_table} WHERE table_name = :tbl
          )
        ORDER BY n.community_name
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tbl=table_name.upper())
            return [row[0] for row in cur.fetchall()]


# ---------------------------------------------------------------------------
# Annotation builders
# ---------------------------------------------------------------------------

def _annotation_community(node: NodeInfo) -> list[str]:
    return [f"[{node.table_name} IN_COMMUNITY {node.community_name}]"]


def _annotation_hub(node: NodeInfo) -> list[str]:
    if not node.is_hub:
        return []
    return [f"[{node.table_name} IS_HUB degree:{node.hub_degree:.1f}]"]


def _annotations_joins_and_affinity(
    table_name: str, edges: list[EdgeInfo]
) -> list[str]:
    """
    Emit JOINS_WITH + affinity annotation pairs for every non-excluded edge.
    Order: HIGH → MEDIUM → LOW
    """
    lines: list[str] = []
    for level in ("HIGH", "MEDIUM", "LOW"):
        for e in [x for x in edges if x.affinity_level == level]:
            lines.append(f"[{table_name} JOINS_WITH {e.other_table}]")
            lines.append(
                f"[{table_name} {level}_AFFINITY {e.other_table}:{e.total_affinity:.2f}]"
            )
    return lines


def _annotation_bridges(
    node: NodeInfo, bridge_communities: list[str]
) -> list[str]:
    if not node.is_bridge or not bridge_communities:
        return []
    all_communities = sorted(set([node.community_name] + bridge_communities))
    span = ":".join(all_communities)
    return [f"[{node.table_name} BRIDGES {span}]"]


def _annotations_join_paths(table_name: str, join_paths_table: str) -> list[str]:
    paths = get_paths_for_table(table_name, join_paths_table)
    return [f"[{table_name} JOINS_PATH {path}]" for path in paths]


# ---------------------------------------------------------------------------
# Token budget enforcement
# ---------------------------------------------------------------------------

def _apply_token_budget(lines: list[str], max_lines: int = _TOKEN_BUDGET_LINES) -> list[str]:
    """
    If annotations exceed budget, drop LOW-affinity lines first (least informative).
    Community, hub, bridge, and join-path lines are preserved.
    """
    if len(lines) <= max_lines:
        return lines

    low_lines = [l for l in lines if "_LOW_AFFINITY" in l or ("JOINS_WITH" in l and _is_low_pair(l, lines))]
    priority_lines = [l for l in lines if l not in low_lines]

    budget_remaining = max_lines - len(priority_lines)
    kept_low = low_lines[:max(0, budget_remaining)]
    return priority_lines + kept_low


def _is_low_pair(joins_with_line: str, all_lines: list[str]) -> bool:
    """True if the JOINS_WITH line's corresponding affinity line is LOW."""
    parts = joins_with_line.strip("[]").split()
    if len(parts) < 3:
        return False
    other = parts[2]
    affinity_line = f"LOW_AFFINITY {other}:"
    return any(affinity_line in l for l in all_lines)


# ---------------------------------------------------------------------------
# Main generator
# ---------------------------------------------------------------------------

def generate_annotations(table_name: str, ctx: SchemaContext) -> list[str]:
    """
    Return the full ordered list of bracket-triple annotation strings for `table_name`.
    Returns [] if the table is not found in the NODES table.
    """
    table_name = table_name.upper()
    node = _load_node_info(table_name, ctx.nodes_table)
    if node is None:
        console.print(f"[red]Table {table_name} not found in {ctx.nodes_table}[/red]")
        return []

    edges = _load_edges(table_name, ctx.edges_table)
    bridge_communities = (
        _load_bridge_communities(table_name, ctx.nodes_table, ctx.edges_table)
        if node.is_bridge else []
    )
    node.bridge_communities = bridge_communities

    lines: list[str] = []
    lines += _annotation_community(node)
    lines += _annotation_hub(node)
    lines += _annotations_joins_and_affinity(table_name, edges)
    lines += _annotation_bridges(node, bridge_communities)
    lines += _annotations_join_paths(table_name, ctx.join_paths_table)

    return _apply_token_budget(lines)


def annotations_as_text(table_name: str, ctx: SchemaContext) -> str:
    """Return annotations as a newline-joined block, suitable for embedding."""
    return "\n".join(generate_annotations(table_name, ctx))


# ---------------------------------------------------------------------------
# All-tables runner
# ---------------------------------------------------------------------------

def _all_table_names(nodes_table: str) -> list[str]:
    """Return all table names from the NODES table."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(f"SELECT table_name FROM {nodes_table} ORDER BY table_name")
            return [row[0] for row in cur.fetchall()]


def generate_all_annotations(ctx: SchemaContext) -> dict[str, list[str]]:
    """
    Generate annotations for every table in the NODES table.
    Returns a dict of {table_name: [annotation_lines]}.
    """
    from rich.progress import track as rich_track

    tables = _all_table_names(ctx.nodes_table)
    console.print(f"Generating annotations for [bold]{len(tables)}[/bold] tables…\n")

    results: dict[str, list[str]] = {}
    for table in rich_track(tables, description="Annotating tables…"):
        results[table] = generate_annotations(table, ctx)

    total_lines = sum(len(v) for v in results.values())
    annotated = sum(1 for v in results.values() if v)
    console.print(f"\n[green]Done.[/green] {annotated}/{len(tables)} tables annotated, "
                  f"{total_lines} total annotation lines.")
    return results


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def _print_annotations(table: str, lines: list[str]) -> None:
    console.print(f"\n[bold cyan]Annotations for {table.upper()}[/bold cyan]")
    for line in lines:
        if "HIGH_AFFINITY" in line:
            console.print(f"  [green]{line}[/green]")
        elif "MEDIUM_AFFINITY" in line:
            console.print(f"  [yellow]{line}[/yellow]")
        elif "LOW_AFFINITY" in line:
            console.print(f"  [dim]{line}[/dim]")
        elif "BRIDGES" in line or "IS_HUB" in line:
            console.print(f"  [bold red]{line}[/bold red]")
        elif "JOINS_PATH" in line:
            console.print(f"  [blue]{line}[/blue]")
        else:
            console.print(f"  {line}")
    console.print(f"\n[dim]{len(lines)} annotation lines[/dim]")


if __name__ == "__main__":
    import src.schemas.university.plugin  # noqa: F401
    from src.schemas.base import get_plugin

    parser = argparse.ArgumentParser(description="Generate SchemaRAG annotations")
    parser.add_argument("--schema", default="university", help="Schema to use (default: university)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--table", help="Single table name (e.g. ENRL_REC)")
    group.add_argument("--all", action="store_true", help="Generate annotations for all tables")
    args = parser.parse_args()

    ctx = get_plugin(args.schema).context

    if args.all:
        from src.annotations.metadata_augmentor import augment_all_tables
        augment_all_tables(ctx)
    else:
        # Upsert into SCHEMA_EMBEDDINGS (creates row if absent, updates if present)
        from src.annotations.metadata_augmentor import augment_table
        augment_table(args.table.upper(), ctx)
        # Re-generate for display
        lines = generate_annotations(args.table.upper(), ctx)
        if lines:
            _print_annotations(args.table, lines)
        console.print(f"[green]Upserted SCHEMA_EMBEDDINGS row for {args.table.upper()} ({len(lines)} annotations)[/green]")
