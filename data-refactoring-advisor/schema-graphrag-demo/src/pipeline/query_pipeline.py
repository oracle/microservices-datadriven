# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Single-call NL→SQL pipeline for the Streamlit app and notebooks.

Usage:
    from src.pipeline.query_pipeline import run_query

    result = run_query("Show diabetic patients with drug-allergy interactions")
    print(result.sql)
    print(result.rows)

Or from CLI:
    python -m src.pipeline.query_pipeline \
        "Which students on financial aid have outstanding bursar holds blocking their graduation audit?"

    python -m src.pipeline.query_pipeline \
        "Which students on financial aid have outstanding bursar holds blocking their graduation audit?" \
        --compare --ddl-baseline
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass, field

from rich.console import Console
from rich.table import Table as RichTable

import re

from src.nl2sql.query_retriever import format_context_block, retrieve_tables
from src.nl2sql.claude_client_ai import generate_sql, run_generated_sql
from src.nl2sql.sql_validator import extract_table_references, is_valid_sql
from src.db.schema_inspector import fetch_ddl_for_tables
from src.schemas.base import SchemaContext

console = Console()


def _default_ctx() -> SchemaContext:
    """Return the university context as the default."""
    from src.schemas.university.plugin import UNIVERSITY_CONTEXT
    return UNIVERSITY_CONTEXT


def _count_total_rows(sql: str) -> int | None:
    """
    Strip FETCH FIRST / ROWNUM clauses from LLM-generated SQL and run a
    COUNT(*) wrapper to get the true total row count (no display cap).
    Returns None if the count query fails.
    """
    # Strip trailing FETCH FIRST N ROWS ONLY (case-insensitive, optional ONLY)
    stripped = re.sub(
        r'\bFETCH\s+FIRST\s+\d+\s+ROWS\s+(?:ONLY\b)?',
        '', sql, flags=re.IGNORECASE,
    ).rstrip().rstrip(';')
    # Also strip bare ROWNUM filters added at the top level
    stripped = re.sub(
        r'\bAND\s+ROWNUM\s*<=\s*\d+', '', stripped, flags=re.IGNORECASE,
    ).strip()
    count_sql = f"SELECT COUNT(*) FROM ({stripped})"
    try:
        _, rows = run_generated_sql(count_sql, max_rows=1)
        return int(rows[0][0]) if rows else None
    except Exception:  # noqa: BLE001
        return None


@dataclass
class QueryResult:
    nl_query: str
    baseline: bool
    retrieved_tables: list[dict]
    context_block: str
    generated_sql: str
    sql_valid: bool
    sql_error: str
    columns: list[str]
    rows: list[tuple]
    table_references: list[str] = field(default_factory=list)
    total_row_count: int | None = None

    @property
    def row_count(self) -> int:
        return len(self.rows)


def run_query(
    nl_query: str,
    ctx: SchemaContext | None = None,
    top_k: int = 8,
    baseline: bool = False,
    ddl_baseline: bool = False,
    no_fk_baseline: bool = False,
    max_result_rows: int = 100,
    count_total: bool = False,
    debug: bool = False,
) -> QueryResult:
    """
    Full NL → SQL → results pipeline.

    baseline=True       → no annotations, no DDL — LLM gets domain description only
    ddl_baseline=True   → DDL only (Haiku selects without annotations) — today's standard RAG
    no_fk_baseline=True → DDL only, FK constraints stripped
    baseline=False      → SchemaRAG mode: DDL + graph-derived annotations
                          Both sides get DDL so the only variable is the annotations.
    """
    if ctx is None:
        ctx = _default_ctx()
    ddl_context = ""
    context_block = ""

    if ddl_baseline or no_fk_baseline:
        # Baseline: Haiku selects tables from names/communities only — no annotation hints
        retrieved = retrieve_tables(
            nl_query, top_k=top_k, baseline=False,
            embeddings_table=ctx.embeddings_table,
            embeddings_baseline_table=ctx.embeddings_baseline_table,
            include_annotations=False,
            debug=debug,
        )
        selected_table_names = [r["table_name"] for r in retrieved]
        ddl_context = fetch_ddl_for_tables(
            selected_table_names,
            schema=ctx.schema_name,
            include_fks=not no_fk_baseline,
        )
    else:
        # Annotated: Haiku selects tables using annotation hints, then LLM gets DDL + annotations
        retrieved = retrieve_tables(
            nl_query, top_k=top_k, baseline=baseline,
            embeddings_table=ctx.embeddings_table,
            embeddings_baseline_table=ctx.embeddings_baseline_table,
            include_annotations=not baseline,
            debug=debug,
        )
        context_block = format_context_block(retrieved, baseline=baseline)
        if not baseline and retrieved:
            # Also provide DDL so the LLM has exact column names alongside annotation context
            selected_table_names = [r["table_name"] for r in retrieved]
            ddl_context = fetch_ddl_for_tables(
                selected_table_names,
                schema=ctx.schema_name,
                include_fks=True,
            )

    generated = generate_sql(
        nl_query,
        context_block=context_block,
        ddl_context=ddl_context,
        schema_name=ctx.schema_name,
        domain_description=ctx.domain_description,
    )

    valid, error = is_valid_sql(generated)
    table_refs = extract_table_references(generated) if valid else []

    columns: list[str] = []
    rows: list[tuple] = []
    total: int | None = None
    if valid:
        try:
            columns, rows = run_generated_sql(generated, max_rows=max_result_rows)
            if count_total:
                total = _count_total_rows(generated)
        except Exception as exc:  # noqa: BLE001
            valid = False
            error = str(exc)

    return QueryResult(
        nl_query=nl_query,
        baseline=baseline,
        retrieved_tables=retrieved,
        context_block=context_block,
        generated_sql=generated,
        sql_valid=valid,
        sql_error=error,
        columns=columns,
        rows=rows,
        table_references=table_refs,
        total_row_count=total,
    )


def run_comparison(
    nl_query: str,
    ctx: SchemaContext | None = None,
    top_k: int = 8,
    max_result_rows: int = 100,
    ddl_baseline: bool = False,
    no_fk_baseline: bool = False,
    count_total: bool = False,
    debug: bool = False,
) -> tuple[QueryResult, QueryResult]:
    """
    Run the same query twice — baseline and annotated — for side-by-side comparison.

    ddl_baseline=False, no_fk_baseline=False → blind baseline (no schema context)
    ddl_baseline=True                        → selected DDL with FK constraints
    no_fk_baseline=True                      → selected DDL, FK constraints stripped
    count_total=True                         → strip FETCH FIRST and run COUNT(*) for true totals
    Returns (baseline_result, annotated_result).
    """
    if ctx is None:
        ctx = _default_ctx()
    baseline_result = run_query(
        nl_query,
        ctx=ctx,
        top_k=top_k,
        baseline=not (ddl_baseline or no_fk_baseline),
        ddl_baseline=ddl_baseline,
        no_fk_baseline=no_fk_baseline,
        max_result_rows=max_result_rows,
        count_total=count_total,
        debug=debug,
    )
    annotated_result = run_query(
        nl_query, ctx=ctx, top_k=top_k, baseline=False,
        max_result_rows=max_result_rows, count_total=count_total,
        debug=debug,
    )
    return baseline_result, annotated_result


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import src.schemas.university.plugin  # noqa: F401
    from src.schemas.base import get_plugin

    parser = argparse.ArgumentParser(description="Run NL→SQL query pipeline")
    parser.add_argument("query", help="Natural language question")
    parser.add_argument("--schema", default="university", help="Schema to query (default: university)")
    parser.add_argument("--top-k", type=int, default=8)
    parser.add_argument("--baseline", action="store_true", help="Use baseline (no annotations, no DDL)")
    parser.add_argument("--ddl-baseline", action="store_true",
                        help="Baseline with selected DDL including FK constraints")
    parser.add_argument("--no-fk-baseline", action="store_true",
                        help="Baseline with selected DDL, FK constraints stripped")
    parser.add_argument("--compare", action="store_true", help="Run side-by-side comparison")
    parser.add_argument("--show-rows", action="store_true", help="Print result rows as a table")
    parser.add_argument("--count-total", action="store_true",
                        help="Strip FETCH FIRST and run COUNT(*) to show true total row count")
    parser.add_argument("--debug-annotations", action="store_true",
                        help="Print the full table index sent to Haiku and which tables it selects")
    args = parser.parse_args()

    plugin = get_plugin(args.schema)
    ctx = plugin.context

    def _print_rows(result: QueryResult) -> None:
        if not result.sql_valid or not result.rows:
            return
        tbl = RichTable(*result.columns, show_lines=False)
        for row in result.rows:
            tbl.add_row(*[str(v) if v is not None else "" for v in row])
        console.print(tbl)

    if args.compare:
        br, ar = run_comparison(
            args.query, ctx=ctx, top_k=args.top_k,
            ddl_baseline=args.ddl_baseline,
            no_fk_baseline=args.no_fk_baseline,
            count_total=args.count_total,
            debug=args.debug_annotations,
        )

        console.rule("[red]Standard RAG (baseline)")
        console.print(f"Tables: {', '.join(t['table_name'] for t in br.retrieved_tables)}")
        console.print(f"\n[dim]{br.generated_sql}[/dim]")
        if br.sql_valid:
            display = f"Rows returned: [bold red]{br.row_count}[/bold red]"
            if br.total_row_count is not None:
                display += f"  (total without limit: [bold red]{br.total_row_count}[/bold red])"
            console.print(display)
            if args.show_rows:
                _print_rows(br)
        else:
            console.print(f"[bold red]SQL Error: {br.sql_error}[/bold red]")

        console.rule("[green]SchemaRAG (annotated)")
        console.print(f"Tables: {', '.join(t['table_name'] for t in ar.retrieved_tables)}")
        console.print(f"\n[dim]{ar.generated_sql}[/dim]")
        if ar.sql_valid:
            display = f"Rows returned: [bold green]{ar.row_count}[/bold green]"
            if ar.total_row_count is not None:
                display += f"  (total without limit: [bold green]{ar.total_row_count}[/bold green])"
            console.print(display)
            if args.show_rows:
                _print_rows(ar)
        else:
            console.print(f"[bold red]SQL Error: {ar.sql_error}[/bold red]")
    else:
        result = run_query(
            args.query, ctx=ctx, top_k=args.top_k, baseline=args.baseline,
            ddl_baseline=args.ddl_baseline, no_fk_baseline=args.no_fk_baseline,
            debug=args.debug_annotations,
        )
        console.print(f"Tables retrieved: {', '.join(t['table_name'] for t in result.retrieved_tables)}")
        console.print(f"\n{result.generated_sql}")
        if result.sql_valid:
            console.print(f"\n[green]{result.row_count} rows returned[/green]")
            if args.show_rows:
                _print_rows(result)
        else:
            console.print(f"\n[red]SQL error: {result.sql_error}[/red]")
