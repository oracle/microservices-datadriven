# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Generate SQL from a natural language question using the Anthropic Claude API.

When context_block is provided (SchemaRAG mode), Claude receives the
graph-derived annotation context — community membership, affinities, bridge
tables, and join paths — and uses them to construct correct multi-hop SQL.

When context_block is omitted (baseline mode), Claude sees only the raw NL
question with no annotation context, mirroring standard vector RAG behaviour.
This enables a direct before/after demo comparison.
"""
from __future__ import annotations

import re

import anthropic

from src.config import settings
from src.db.connection import get_connection

_SYSTEM_WITH_CONTEXT = """\
You are an expert Oracle SQL generator for a {domain_description} database.
The schema is owned by {schema_name} and its tables are organised into domain communities.

Below is the graph-derived annotation context for the tables most relevant
to the user's question. Use the [BRIDGES], [JOINS_PATH], [IS_HUB], and
affinity annotations to choose correct join paths and bridge tables.

{context_block}

{ddl_section}

Rules:
- Output ONLY a single SQL statement — no explanation, no markdown fences, no semicolons.
- Never output multiple SQL statements.
- Use {schema_name}.<TABLE> schema-qualified table names.
- Prefer join paths indicated by JOINS_PATH annotations.
- Always include bridge tables flagged by BRIDGES annotations.
- Limit results to 100 rows unless the question asks for aggregates.
- When filtering by categorical string values (specialty, status, type, department name, etc.),
  use UPPER(column) LIKE '%KEYWORD%' rather than exact matches unless the context provides
  the exact stored value.
- When using aggregate functions (COUNT, SUM, AVG, etc.) alongside non-aggregated columns,
  either GROUP BY all non-aggregated columns, or use a CTE/subquery to separate the
  aggregation from the row-level detail.
"""

_SYSTEM_NO_CONTEXT = """\
You are an expert Oracle SQL generator for a {domain_description} database schema
owned by the {schema_name} user.

Rules:
- Output ONLY a single SQL statement — no explanation, no markdown fences, no semicolons.
- Never output multiple SQL statements.
- Use {schema_name}.<TABLE> schema-qualified table names.
- Limit results to 100 rows unless the question asks for aggregates.
- When filtering by categorical string values (specialty, status, type, department name, etc.),
  use UPPER(column) LIKE '%KEYWORD%' rather than exact matches unless the context provides
  the exact stored value.
- When using aggregate functions (COUNT, SUM, AVG, etc.) alongside non-aggregated columns,
  either GROUP BY all non-aggregated columns, or use a CTE/subquery to separate the
  aggregation from the row-level detail.
"""

_SYSTEM_WITH_DDL = """\
You are an expert Oracle SQL generator for a {domain_description} database schema
owned by the {schema_name} user.

Below is the DDL schema for the tables most relevant to the user's question —
columns, data types, primary keys, foreign keys, and column comments.
Use this to write accurate SQL.

{ddl_context}

Rules:
- Output ONLY a single SQL statement — no explanation, no markdown fences, no semicolons.
- Never output multiple SQL statements.
- Use {schema_name}.<TABLE> schema-qualified table names.
- Limit results to 100 rows unless the question asks for aggregates.
- When filtering by categorical string values (specialty, status, type, department name, etc.),
  use UPPER(column) LIKE '%KEYWORD%' rather than exact matches unless the context provides
  the exact stored value.
- When using aggregate functions (COUNT, SUM, AVG, etc.) alongside non-aggregated columns,
  either GROUP BY all non-aggregated columns, or use a CTE/subquery to separate the
  aggregation from the row-level detail.
"""


def _extract_first_statement(sql: str) -> str:
    """
    Safety net: if Claude returns multiple statements despite instructions,
    extract only the first complete one by splitting on a semicolon followed
    by a blank line or a new top-level keyword.
    """
    parts = re.split(r";\s*\n\s*(?=SELECT|WITH|INSERT|UPDATE|DELETE)", sql, flags=re.IGNORECASE)
    first = parts[0].strip()
    return first.rstrip(";").strip()


def generate_sql(
    nl_query: str,
    context_block: str = "",
    ddl_context: str = "",
    schema_name: str = "SCHEMARAG",
    domain_description: str = "healthcare",
) -> str:
    """
    Call Claude to generate Oracle SQL for nl_query.

    Args:
        nl_query: The natural language question from the user.
        context_block: Graph-derived annotation context (SchemaRAG mode).
                       Pass empty string for baseline mode.
        ddl_context: DDL schema string for selected tables.
                     Used for the DDL baseline — gives the LLM selected table
                     DDL (columns, types, PKs, FKs, comments) but no graph-derived
                     annotations. Ignored when context_block is provided.
        schema_name: Oracle schema owner used in table name qualification.
        domain_description: Short description of the domain for the system prompt.

    Returns:
        Generated SQL string ready to execute against Oracle.
    """
    client = anthropic.Anthropic(api_key=settings.anthropic_api_key)

    if context_block:
        ddl_section = (
            f"Below is the DDL for the selected tables — use exact column names from this DDL:\n\n{ddl_context}"
            if ddl_context else ""
        )
        system_prompt = _SYSTEM_WITH_CONTEXT.format(
            context_block=context_block,
            ddl_section=ddl_section,
            schema_name=schema_name,
            domain_description=domain_description,
        )
    elif ddl_context:
        system_prompt = _SYSTEM_WITH_DDL.format(
            ddl_context=ddl_context,
            schema_name=schema_name,
            domain_description=domain_description,
        )
    else:
        system_prompt = _SYSTEM_NO_CONTEXT.format(
            schema_name=schema_name,
            domain_description=domain_description,
        )

    message = client.messages.create(
        model=settings.anthropic_model,
        max_tokens=4096,
        temperature=0,
        system=system_prompt,
        messages=[{"role": "user", "content": nl_query}],
    )

    sql = message.content[0].text.strip()

    # Strip markdown code fences wherever they appear (start, end, or both)
    if "```" in sql:
        lines = sql.splitlines()
        sql = "\n".join(
            line for line in lines if not line.strip().startswith("```")
        ).strip()

    sql = _extract_first_statement(sql)

    return sql


def run_generated_sql(
    generated_sql: str,
    max_rows: int = 100,
) -> tuple[list[str], list[tuple]]:
    """
    Execute the SQL returned by Claude and return (column_names, rows).
    Raises on syntax errors so the caller can show the error in the demo UI.
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(generated_sql)
            col_names = [d[0] for d in cur.description] if cur.description else []
            rows = cur.fetchmany(max_rows)
    return col_names, rows
