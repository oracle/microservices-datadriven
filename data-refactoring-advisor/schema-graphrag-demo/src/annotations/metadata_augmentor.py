# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Combine raw table metadata (columns, FK refs, row count) with
SchemaRAG annotations into a single embeddable document.

Document structure:
  TABLE: <name>
  COMMUNITY: <name>
  ROW_COUNT: <n>
  DESCRIPTION: <table comments if any>

  COLUMNS:
    <name> (<type>) [PK] [FK→<ref_table>] — <comment if any>
    …

  ANNOTATIONS:
    [T IN_COMMUNITY …]
    [T IS_HUB …]
    …

Annotations are placed BEFORE column details in the token budget prioritisation —
they are more discriminative for retrieval than column type information.
"""
from __future__ import annotations

from src.annotations.annotation_generator import annotations_as_text, generate_annotations
from src.db.schema_inspector import TableInfo, get_table_info
from src.db.vector_store import upsert_embedding_row
from src.schemas.base import SchemaContext


# ---------------------------------------------------------------------------
# Document builders
# ---------------------------------------------------------------------------

def build_base_metadata(info: TableInfo) -> str:
    """
    Construct the plain (no-annotation) metadata document for the baseline table.
    Used in the baseline embeddings table.
    """
    lines: list[str] = []
    lines.append(f"TABLE: {info.table_name}")
    if info.num_rows is not None:
        lines.append(f"ROW_COUNT: {info.num_rows:,}")
    if info.comments:
        lines.append(f"DESCRIPTION: {info.comments}")

    lines.append("\nCOLUMNS:")
    for col in info.columns:
        parts = [f"  {col.name} ({col.data_type})"]
        if col.name in info.pk_columns:
            parts.append("[PK]")
        fk_targets = [ref_table for (c, ref_table) in info.fk_refs if c == col.name]
        for ref in fk_targets:
            parts.append(f"[FK→{ref}]")
        if col.comments:
            parts.append(f"— {col.comments}")
        lines.append(" ".join(parts))

    return "\n".join(lines)


def build_augmented_text(info: TableInfo, annotation_lines: list[str]) -> str:
    """
    Construct the SchemaRAG-enriched document.
    Annotations come first to maximise their weight in the embedding space.
    """
    lines: list[str] = []
    lines.append(f"TABLE: {info.table_name}")
    if info.num_rows is not None:
        lines.append(f"ROW_COUNT: {info.num_rows:,}")
    if info.comments:
        lines.append(f"DESCRIPTION: {info.comments}")

    if annotation_lines:
        lines.append("\nANNOTATIONS:")
        for ann in annotation_lines:
            lines.append(f"  {ann}")

    lines.append("\nCOLUMNS:")
    for col in info.columns:
        parts = [f"  {col.name} ({col.data_type})"]
        if col.name in info.pk_columns:
            parts.append("[PK]")
        fk_targets = [ref_table for (c, ref_table) in info.fk_refs if c == col.name]
        for ref in fk_targets:
            parts.append(f"[FK→{ref}]")
        if col.comments:
            parts.append(f"— {col.comments}")
        lines.append(" ".join(parts))

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Community name helper
# ---------------------------------------------------------------------------

def _get_community_name(table_name: str, nodes_table: str) -> str:
    """Return community name for a table from the NODES table, or 'Unknown'."""
    from src.db.connection import get_connection
    sql = f"SELECT community_name FROM {nodes_table} WHERE table_name = :tbl"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tbl=table_name.upper())
            row = cur.fetchone()
    return row[0] if row and row[0] else "Unknown"


def _table_exists_in_nodes(table_name: str, nodes_table: str) -> bool:
    """Return True when the workload graph contains this table."""
    from src.db.connection import get_connection
    sql = f"SELECT COUNT(*) FROM {nodes_table} WHERE table_name = :tbl"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tbl=table_name.upper())
            (count,) = cur.fetchone()
    return bool(count)


# ---------------------------------------------------------------------------
# Per-table augmentation
# ---------------------------------------------------------------------------

def augment_table(table_name: str, ctx: SchemaContext) -> int:
    """
    Build metadata + annotations for one table and upsert both
    annotated and baseline embedding rows.
    Returns the annotation count for the table.
    """
    table_name = table_name.upper()
    if not _table_exists_in_nodes(table_name, ctx.nodes_table):
        raise ValueError(
            f"Table {table_name} is not present in {ctx.nodes_table}. "
            "Run --step extract first, or choose a table that appears in the captured workload."
        )

    info = get_table_info(table_name, schema=ctx.schema_name)
    annotation_lines = generate_annotations(table_name, ctx)
    community_name = _get_community_name(table_name, ctx.nodes_table)

    base_metadata = build_base_metadata(info)
    augmented_text = build_augmented_text(info, annotation_lines)

    # Annotated row
    upsert_embedding_row(
        table_name=table_name,
        community_name=community_name,
        base_metadata=base_metadata,
        augmented_text=augmented_text,
        annotation_count=len(annotation_lines),
        baseline=False,
        embeddings_table=ctx.embeddings_table,
        embeddings_baseline_table=ctx.embeddings_baseline_table,
    )

    # Baseline row (no annotations)
    upsert_embedding_row(
        table_name=table_name,
        community_name=community_name,
        base_metadata=base_metadata,
        augmented_text=augmented_text,
        annotation_count=0,
        baseline=True,
        embeddings_table=ctx.embeddings_table,
        embeddings_baseline_table=ctx.embeddings_baseline_table,
    )

    return len(annotation_lines)


def augment_all_tables(ctx: SchemaContext) -> dict[str, int]:
    """
    Run augment_table for all tables in the NODES table.
    Returns dict: table_name → annotation_count.
    """
    from src.db.connection import get_connection
    from rich.console import Console
    from rich.progress import track

    console = Console()
    sql = f"SELECT table_name FROM {ctx.nodes_table} ORDER BY table_name"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            tables = [row[0] for row in cur.fetchall()]

    results: dict[str, int] = {}
    for tbl in track(tables, description="Augmenting tables…"):
        count = augment_table(tbl, ctx)
        results[tbl] = count

    console.print(
        f"[green]Augmented {len(results)} tables — "
        f"avg {sum(results.values()) / max(len(results), 1):.1f} annotations/table[/green]"
    )
    return results
