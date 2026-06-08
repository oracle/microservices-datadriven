"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Orchestrate embedding of all tables using OCI GenAI via DBMS_VECTOR_CHAIN.

Two passes:
  1. baseline=False  → embed augmented_text  → <schema>_EMBEDDINGS
  2. baseline=True   → embed base_metadata   → <schema>_EMBEDDINGS_BASELINE

The embedding SQL runs inside the database (DBMS_VECTOR_CHAIN.UTL_TO_EMBEDDING),
so this module just issues UPDATE statements for each table row.

Usage:
    python -m src.embeddings.embedding_pipeline
    python -m src.embeddings.embedding_pipeline --baseline-only
    python -m src.embeddings.embedding_pipeline --annotated-only
"""
from __future__ import annotations

import argparse

from rich.console import Console
from rich.progress import track

from src.config import settings
from src.db.connection import get_connection
from src.db.vector_store import fetch_all_augmented_texts

console = Console()


# ---------------------------------------------------------------------------
# Core: embed one table row inside the database
# ---------------------------------------------------------------------------

def _embed_row_in_db(
    table_name: str,
    baseline: bool,
    embeddings_table: str,
    embeddings_baseline_table: str,
) -> None:
    """
    Issue an UPDATE that calls UTL_TO_EMBEDDING inside ADB.
    The text column and target table differ for baseline vs annotated.
    """
    target_table = embeddings_baseline_table if baseline else embeddings_table
    text_col = "base_metadata" if baseline else "augmented_text"

    sql = f"""
        UPDATE {target_table}
        SET embedding   = DBMS_VECTOR_CHAIN.UTL_TO_EMBEDDING(
                              {text_col},
                              json('{settings.embed_json}')
                          ),
            embedded_at = SYSTIMESTAMP
        WHERE table_name = :tbl
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tbl=table_name.upper())
            if cur.rowcount == 0:
                console.print(f"[yellow]  WARN: no row found for {table_name} in {target_table}[/yellow]")


# ---------------------------------------------------------------------------
# Batch runners
# ---------------------------------------------------------------------------

def embed_all(
    baseline: bool = False,
    embeddings_table: str = "SCHEMA_EMBEDDINGS",
    embeddings_baseline_table: str = "SCHEMA_EMBEDDINGS_BASELINE",
) -> None:
    """Embed all tables in the given embeddings table (or baseline table)."""
    rows = fetch_all_augmented_texts(
        baseline=baseline,
        embeddings_table=embeddings_table,
        embeddings_baseline_table=embeddings_baseline_table,
    )
    label = "baseline" if baseline else "annotated"
    target = embeddings_baseline_table if baseline else embeddings_table
    if not rows:
        console.print(f"[red]No rows found in {target} — run augment step first.[/red]")
        return

    console.print(f"\nEmbedding [bold]{len(rows)}[/bold] tables ({label}) → {target}…")
    errors = 0
    for row in track(rows, description=f"Embedding {label}…"):
        try:
            _embed_row_in_db(
                row["table_name"],
                baseline=baseline,
                embeddings_table=embeddings_table,
                embeddings_baseline_table=embeddings_baseline_table,
            )
        except Exception as exc:  # noqa: BLE001
            errors += 1
            console.print(f"[red]  ERROR {row['table_name']}: {exc!s:.100}[/red]")

    console.print(
        f"[green]{label.capitalize()} embedding complete — "
        f"{len(rows) - errors} ok, {errors} errors[/green]"
    )


def run_embedding_pipeline(
    run_annotated: bool = True,
    run_baseline: bool = True,
    embeddings_table: str = "SCHEMA_EMBEDDINGS",
    embeddings_baseline_table: str = "SCHEMA_EMBEDDINGS_BASELINE",
) -> None:
    """Run annotated and/or baseline embedding passes."""
    console.rule("[bold cyan]Embedding Pipeline")
    if run_annotated:
        embed_all(
            baseline=False,
            embeddings_table=embeddings_table,
            embeddings_baseline_table=embeddings_baseline_table,
        )
    if run_baseline:
        embed_all(
            baseline=True,
            embeddings_table=embeddings_table,
            embeddings_baseline_table=embeddings_baseline_table,
        )
    console.print("[green]All embeddings complete.[/green]")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import src.schemas.university.plugin  # noqa: F401
    from src.schemas.base import get_plugin

    parser = argparse.ArgumentParser(description="Embed all table rows via OCI GenAI")
    parser.add_argument("--schema", default="university", help="Schema to embed (default: university)")
    parser.add_argument("--baseline-only", action="store_true")
    parser.add_argument("--annotated-only", action="store_true")
    args = parser.parse_args()

    plugin = get_plugin(args.schema)
    ctx = plugin.context

    run_embedding_pipeline(
        run_annotated=not args.baseline_only,
        run_baseline=not args.annotated_only,
        embeddings_table=ctx.embeddings_table,
        embeddings_baseline_table=ctx.embeddings_baseline_table,
    )
