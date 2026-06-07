"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Build a NetworkX weighted undirected graph from the schema's EDGES table.

Only edges with affinity_level != 'EXCLUDED' are included — nodes that are
completely unrelated to every other table in the schema are not meaningful
members of any community.
"""
from __future__ import annotations

import networkx as nx
from rich.console import Console

from src.db.connection import get_connection
from src.schemas.base import SchemaContext

console = Console()


def load_graph(ctx: SchemaContext, include_excluded: bool = False) -> nx.Graph:
    """
    Return a NetworkX Graph where:
      - nodes  = table names (upper-case strings)
      - edges  = affinity pairs; edge weight = total_affinity
    """
    level_filter = "" if include_excluded else "WHERE affinity_level <> 'EXCLUDED'"
    sql = f"""
        SELECT table_name_1, table_name_2, total_affinity, affinity_level
        FROM {ctx.edges_table}
        {level_filter}
    """
    G = nx.Graph()
    edge_count = 0
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            for t1, t2, weight, level in cur.fetchall():
                G.add_edge(
                    str(t1), str(t2),
                    weight=float(weight),
                    affinity_level=str(level),
                )
                edge_count += 1

    # Ensure isolated tables appear as nodes in the graph.
    node_sql = f"SELECT table_name FROM {ctx.nodes_table}"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(node_sql)
            for (tbl,) in cur.fetchall():
                G.add_node(str(tbl))

    console.print(
        f"Graph loaded — {G.number_of_nodes()} nodes, "
        f"{G.number_of_edges()} edges (include_excluded={include_excluded})"
    )
    return G


def get_hub_tables(G: nx.Graph, min_degree: int | None = None) -> list[str]:
    """Return table names whose connection count meets the hub threshold."""
    if min_degree is None:
        from src.config import settings
        min_degree = settings.hub_degree_threshold
    hubs = [tbl for tbl, deg in G.degree() if deg >= min_degree]
    return sorted(hubs)


def get_bridge_tables(G: nx.Graph, partition: dict[str, int]) -> list[str]:
    """
    Return tables whose neighbours span 2 or more distinct communities.
    `partition` maps table_name → community_id.
    """
    bridges = []
    for node in G.nodes():
        neighbor_communities = {
            partition[nb] for nb in G.neighbors(node)
            if nb in partition
        }
        if len(neighbor_communities) >= 2:
            bridges.append(node)
    return sorted(bridges)
