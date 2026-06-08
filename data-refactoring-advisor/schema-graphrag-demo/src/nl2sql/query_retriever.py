"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Retrieve table annotations from the schema's embeddings table for injection
into Claude's context.

Retrieval strategy (Option A — two-step Claude):
  Step 1: Fast Haiku call — given the NL query and all table names, ask which
          tables are relevant. Returns a filtered short list.
  Step 2: Full Opus call in claude_client_ai.py — receives only the relevant
          tables' annotations for SQL generation.
"""
from __future__ import annotations

import json

import anthropic

from src.config import settings
from src.db.connection import get_connection


# ---------------------------------------------------------------------------
# DB fetch — all table annotations
# ---------------------------------------------------------------------------

def _fetch_all_rows(
    embeddings_table: str,
    embeddings_baseline_table: str,
    baseline: bool = False,
) -> list[dict]:
    """Fetch all rows from the annotated or baseline embeddings table."""
    if baseline:
        sql = f"""
            SELECT table_name,
                   NULL AS community_name,
                   base_metadata AS augmented_text
            FROM {embeddings_baseline_table}
            ORDER BY table_name
        """
    else:
        sql = f"""
            SELECT table_name,
                   community_name,
                   augmented_text
            FROM {embeddings_table}
            ORDER BY table_name
        """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            col_names = [d[0].lower() for d in cur.description]
            return [dict(zip(col_names, row)) for row in cur.fetchall()]


# ---------------------------------------------------------------------------
# Step 1 — Claude Haiku relevance filter
# ---------------------------------------------------------------------------

def _select_relevant_tables(
    nl_query: str,
    all_rows: list[dict],
    include_annotations: bool = True,
    debug: bool = False,
) -> list[str]:
    """
    Ask Claude Haiku which tables from the full list are relevant to nl_query.
    Returns a list of upper-cased table names.

    include_annotations=True  → annotated mode: Haiku sees JOINS_WITH/BRIDGES
                                annotations so it can discover XX_ custom tables.
    include_annotations=False → baseline mode: Haiku sees only table names and
                                communities, simulating a system without graph
                                annotations. XX_ tables are unknown to the LLM.
    """
    index_lines = []
    for row in all_rows:
        entry = f"- {row['table_name']} (community: {row.get('community_name') or 'unknown'})"
        if include_annotations:
            aug_text = row.get("augmented_text", "") or ""
            if hasattr(aug_text, "read"):
                aug_text = aug_text.read()
            aug_text = str(aug_text)
            ann_lines = [
                l.strip() for l in aug_text.splitlines()
                if l.strip().startswith("[")
            ]
            if ann_lines:
                # JOINS_PATH and BRIDGES first — critical for bridge/XX_ table discovery.
                # Cap raised from 6 → 25: original 6 was too conservative for a 200-table
                # schema; busy hub tables exhaust the window before JOINS_PATH appears.
                # Top-K retrieval (~15-30 tables) keeps prompt size manageable (~44K chars).
                priority = [l for l in ann_lines if "JOINS_PATH" in l or "BRIDGES" in l]
                others   = [l for l in ann_lines if "JOINS_PATH" not in l and "BRIDGES" not in l]
                sorted_ann = priority + others
                entry += "\n  " + " | ".join(sorted_ann[:25])
        index_lines.append(entry)

    table_index = "\n".join(index_lines)

    if debug:
        print("\n" + "━" * 60)
        print("DEBUG — Table index sent to Haiku:")
        print("━" * 60)
        print(table_index)
        print("━" * 60 + "\n")

    if include_annotations:
        prompt = f"""You are a database schema expert. Given a natural language query and a list of
database tables with their communities and relationship annotations, identify which tables
are needed to answer the query.

Pay close attention to JOINS_WITH and BRIDGES annotations — they reveal join paths that
are not obvious from table names alone.

Tables available:
{table_index}

Query: {nl_query}

Return ONLY a JSON array of the relevant table names, e.g. ["PATIENTS", "ENCOUNTERS"].
Include all tables needed for joins, not just the ones directly mentioned.
No explanation — just the JSON array."""
    else:
        prompt = f"""You are a database schema expert. Given a natural language query and a list of
database tables with their communities, identify which tables are needed to answer the query.

Tables available:
{table_index}

Query: {nl_query}

Return ONLY a JSON array of the relevant table names, e.g. ["PATIENTS", "ENCOUNTERS"].
Include all tables needed for joins, not just the ones directly mentioned.
No explanation — just the JSON array."""

    client = anthropic.Anthropic(api_key=settings.anthropic_api_key)
    message = client.messages.create(
        model=settings.anthropic_retrieval_model,
        max_tokens=256,
        messages=[{"role": "user", "content": prompt}],
    )

    raw = message.content[0].text.strip()
    if raw.startswith("```"):
        raw = "\n".join(
            line for line in raw.splitlines() if not line.startswith("```")
        ).strip()

    try:
        names = json.loads(raw)
        result = [n.upper() for n in names if isinstance(n, str)]
        if debug:
            print(f"DEBUG — Haiku selected: {result}\n")
        return result
    except (json.JSONDecodeError, TypeError):
        return [row["table_name"] for row in all_rows]


# ---------------------------------------------------------------------------
# Public interface
# ---------------------------------------------------------------------------

def retrieve_tables(
    nl_query: str,
    top_k: int = 8,
    baseline: bool = False,
    embeddings_table: str = "SCHEMA_EMBEDDINGS",
    embeddings_baseline_table: str = "SCHEMA_EMBEDDINGS_BASELINE",
    include_annotations: bool = True,
    debug: bool = False,
) -> list[dict]:
    """
    Return only the tables relevant to nl_query.

    baseline=True          → returns empty list (no context for blind baseline).
    include_annotations=True  → annotated mode: Haiku sees JOINS_WITH/BRIDGES to
                                discover XX_ custom tables.
    include_annotations=False → DDL baseline mode: Haiku sees only names/communities,
                                matching what a system without graph annotations would do.

    top_k is accepted for API compatibility with future vector-search implementation.
    """
    if baseline:
        return []

    all_rows = _fetch_all_rows(embeddings_table, embeddings_baseline_table, baseline=False)
    relevant_names = _select_relevant_tables(
        nl_query, all_rows, include_annotations=include_annotations, debug=debug
    )
    relevant = [r for r in all_rows if r["table_name"] in relevant_names]

    return relevant if relevant else all_rows


def format_context_block(rows: list[dict], baseline: bool = False) -> str:
    """
    Format retrieved rows as a context block for Claude's system prompt.
    In baseline mode returns empty string — Claude gets no annotation context.
    """
    if baseline:
        return ""

    lines = []
    for row in rows:
        aug_text = row.get("augmented_text", "")
        if not aug_text:
            continue

        aug_lines = [l.rstrip() for l in str(aug_text).splitlines()]
        annotation_lines = [l.strip() for l in aug_lines if l.strip().startswith("[")]

        column_lines = []
        in_columns = False
        for l in aug_lines:
            stripped = l.strip()
            if stripped == "COLUMNS:":
                in_columns = True
                continue
            if in_columns:
                if stripped.startswith("TABLE:") or stripped.startswith("ANNOTATIONS:"):
                    break
                if stripped:
                    column_lines.append(stripped)

        lines.append(f"--- {row['table_name']} ({row.get('community_name', '')})")
        if annotation_lines:
            lines.extend(annotation_lines)
        if column_lines:
            lines.append("COLUMNS:")
            lines.extend(f"  {c}" for c in column_lines)
        lines.append("")

    return "\n".join(lines)
