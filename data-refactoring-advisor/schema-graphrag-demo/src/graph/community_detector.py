"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Run Louvain community detection on the affinity graph and persist results
to the schema's NODES table.

Uses python-louvain (import community) with random_state=42 for reproducibility.
Expected result: 10 communities matching the university schema design.
"""
from __future__ import annotations

import community as community_louvain  # python-louvain
import networkx as nx
from rich.console import Console
from rich.table import Table

from src.config import settings
from src.db.connection import get_connection
from src.graph.graph_builder import get_bridge_tables, get_hub_tables, load_graph
from src.schemas.base import SchemaContext

console = Console()


# ---------------------------------------------------------------------------
# Detection
# ---------------------------------------------------------------------------

def detect_communities(
    G: nx.Graph | None = None,
    ctx: SchemaContext | None = None,
    random_state: int = 42,
) -> dict[str, int]:
    """
    Run Louvain and return a partition dict: table_name → community_id.
    If G is None and ctx is provided, loads the full graph (including EXCLUDED edges).
    """
    if G is None:
        if ctx is None:
            raise ValueError("Either G or ctx must be provided")
        G = load_graph(ctx, include_excluded=True)

    partition: dict[str, int] = community_louvain.best_partition(
        G, weight="weight", random_state=random_state
    )
    n_communities = len(set(partition.values()))
    console.print(f"Louvain detected [bold]{n_communities}[/bold] communities")
    return partition


# ---------------------------------------------------------------------------
# Persist
# ---------------------------------------------------------------------------

def _persist_community_assignments(
    partition: dict[str, int],
    community_names: dict[int, str],
    bridge_tables: list[str],
    hub_tables: list[str],
    G: nx.Graph,
    ctx: SchemaContext,
) -> None:
    """Write community_id, community_name, is_bridge, is_hub, hub_degree to the NODES table."""
    connection_counts = dict(G.degree())

    sql = f"""
        UPDATE {ctx.nodes_table}
        SET community_id   = :cid,
            community_name = :cname,
            is_bridge      = :bridge,
            is_hub         = :hub,
            hub_degree     = :hdeg
        WHERE table_name = :tbl
    """
    rows = []
    for tbl, cid in partition.items():
        cname = community_names.get(cid, f"Community_{cid}")
        is_bridge = 1 if tbl in bridge_tables else 0
        is_hub = 1 if tbl in hub_tables else 0
        hub_degree = float(connection_counts.get(tbl, 0))
        rows.append(dict(
            tbl=tbl, cid=cid, cname=cname,
            bridge=is_bridge, hub=is_hub, hdeg=hub_degree,
        ))

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.executemany(sql, rows)

    console.print(
        f"Updated [bold]{len(rows)}[/bold] rows in {ctx.nodes_table}  "
        f"(bridges={len(bridge_tables)}  hubs={len(hub_tables)})"
    )


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def _print_community_report(
    partition: dict[str, int],
    community_names: dict[int, str],
    bridge_tables: list[str],
    hub_tables: list[str],
) -> None:
    from collections import defaultdict

    by_community: dict[str, list[str]] = defaultdict(list)
    for tbl, cid in partition.items():
        by_community[community_names.get(cid, f"C{cid}")].append(tbl)

    t = Table(title="Community Detection Results", show_lines=True)
    t.add_column("Community", style="cyan", min_width=20)
    t.add_column("Tables", style="white")
    t.add_column("Bridges", style="yellow")
    t.add_column("Hubs", style="green")

    for cname, tables in sorted(by_community.items()):
        b = [tbl for tbl in tables if tbl in bridge_tables]
        h = [tbl for tbl in tables if tbl in hub_tables]
        t.add_row(
            cname,
            ", ".join(sorted(tables)),
            ", ".join(sorted(b)) or "—",
            ", ".join(sorted(h)) or "—",
        )
    console.print(t)


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def run_community_detection(
    ctx: SchemaContext,
    community_names: dict[int, str] | None = None,
) -> dict[str, int]:
    """
    Full pipeline:
      load graph → detect communities → identify bridges/hubs → persist → report
    Returns the partition dict.
    """
    console.rule("[bold cyan]Community Detection")
    G_full = load_graph(ctx, include_excluded=True)
    partition = detect_communities(G_full)

    G_sig = load_graph(ctx, include_excluded=False)
    bridge_tables = get_bridge_tables(G_sig, partition)
    hub_tables = get_hub_tables(G_sig, min_degree=settings.hub_degree_threshold)

    if community_names is None:
        community_names = {cid: f"Community_{cid}" for cid in set(partition.values())}

    _persist_community_assignments(partition, community_names, bridge_tables, hub_tables, G_sig, ctx)
    _print_community_report(partition, community_names, bridge_tables, hub_tables)
    return partition


if __name__ == "__main__":
    import argparse
    import src.schemas.university.plugin  # noqa: F401
    from src.schemas.base import get_plugin

    parser = argparse.ArgumentParser(description="Run community detection")
    parser.add_argument("--schema", default="university", help="Schema to use (default: university)")
    args = parser.parse_args()

    ctx = get_plugin(args.schema).context
    run_community_detection(ctx)
