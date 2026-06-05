"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Reads live schema metadata from ADB data dictionary views.
Used by the annotation pipeline to build per-table metadata documents.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional

from src.db.connection import get_connection


@dataclass
class ColumnInfo:
    name: str
    data_type: str
    nullable: bool
    data_length: Optional[int]
    data_precision: Optional[int]
    comments: Optional[str]


@dataclass
class TableInfo:
    table_name: str
    num_rows: Optional[int]
    comments: Optional[str]
    columns: list[ColumnInfo] = field(default_factory=list)
    pk_columns: list[str] = field(default_factory=list)
    fk_refs: list[tuple[str, str]] = field(default_factory=list)  # (col, ref_table)


def get_all_table_names(
    schema: str = "SCHEMARAG",
    exclude_tables: frozenset[str] = frozenset(),
) -> list[str]:
    if exclude_tables:
        not_in_clause = "AND table_name NOT IN ({})".format(
            ",".join(f"'{t.upper()}'" for t in sorted(exclude_tables))
        )
    else:
        not_in_clause = ""
    sql = f"""
        SELECT table_name
        FROM all_tables
        WHERE owner = :schema
          {not_in_clause}
        ORDER BY table_name
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, schema=schema.upper())
            return [row[0] for row in cur.fetchall()]


def get_table_info(table_name: str, schema: str = "SCHEMARAG") -> TableInfo:
    schema = schema.upper()
    table_name = table_name.upper()

    with get_connection() as conn:
        # Table-level comments + row count
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT t.num_rows, c.comments
                FROM all_tables t
                LEFT JOIN all_tab_comments c
                  ON c.owner = t.owner AND c.table_name = t.table_name
                WHERE t.owner = :schema AND t.table_name = :tbl
                """,
                schema=schema, tbl=table_name,
            )
            row = cur.fetchone()
            num_rows = row[0] if row else None
            table_comments = row[1] if row else None

        # Columns
        columns: list[ColumnInfo] = []
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT c.column_name, c.data_type, c.nullable,
                       c.data_length, c.data_precision, cc.comments
                FROM all_tab_columns c
                LEFT JOIN all_col_comments cc
                  ON cc.owner = c.owner
                 AND cc.table_name = c.table_name
                 AND cc.column_name = c.column_name
                WHERE c.owner = :schema AND c.table_name = :tbl
                ORDER BY c.column_id
                """,
                schema=schema, tbl=table_name,
            )
            for r in cur.fetchall():
                columns.append(ColumnInfo(
                    name=r[0], data_type=r[1],
                    nullable=(r[2] == "Y"),
                    data_length=r[3], data_precision=r[4],
                    comments=r[5],
                ))

        # Primary key columns
        pk_columns: list[str] = []
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT cc.column_name
                FROM all_constraints ac
                JOIN all_cons_columns cc
                  ON cc.owner = ac.owner
                 AND cc.constraint_name = ac.constraint_name
                WHERE ac.owner = :schema
                  AND ac.table_name = :tbl
                  AND ac.constraint_type = 'P'
                ORDER BY cc.position
                """,
                schema=schema, tbl=table_name,
            )
            pk_columns = [r[0] for r in cur.fetchall()]

        # Foreign key references
        fk_refs: list[tuple[str, str]] = []
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT cc.column_name, rc.table_name AS ref_table
                FROM all_constraints ac
                JOIN all_cons_columns cc
                  ON cc.owner = ac.owner
                 AND cc.constraint_name = ac.constraint_name
                JOIN all_constraints rc
                  ON rc.owner = ac.r_owner
                 AND rc.constraint_name = ac.r_constraint_name
                WHERE ac.owner = :schema
                  AND ac.table_name = :tbl
                  AND ac.constraint_type = 'R'
                ORDER BY cc.position
                """,
                schema=schema, tbl=table_name,
            )
            fk_refs = [(r[0], r[1]) for r in cur.fetchall()]

    return TableInfo(
        table_name=table_name,
        num_rows=num_rows,
        comments=table_comments,
        columns=columns,
        pk_columns=pk_columns,
        fk_refs=fk_refs,
    )


def fetch_ddl_for_tables(
    table_names: list[str],
    schema: str = "SCHEMARAG",
    include_fks: bool = True,
) -> str:
    """
    Build a DDL summary string for a specific list of tables.

    Used by the DDL baseline to inject schema context for only the tables
    selected by the Haiku retrieval step — matching how real NL2SQL tools
    work (selected tables, not the full schema).

    include_fks=False simulates enterprise schemas (EBS, Fusion, data warehouses)
    where FK constraints are disabled or never defined. The LLM receives only
    column names, data types, and column comments — no structural join guidance.
    """
    sections: list[str] = []
    for table_name in sorted(table_names):
        info = get_table_info(table_name, schema=schema)
        lines: list[str] = [f"TABLE: {info.table_name}"]

        for col in info.columns:
            parts = [f"  {col.name}  {col.data_type}"]
            if col.name in info.pk_columns:
                parts.append("PK")
            if include_fks:
                fk_tables = [ref_table for col_name, ref_table in info.fk_refs if col_name == col.name]
                if fk_tables:
                    parts.append(f"FK→{fk_tables[0]}")
            if not col.nullable:
                parts.append("NOT NULL")
            line = "  ".join(parts)
            if col.comments:
                line += f"  -- {col.comments}"
            lines.append(line)

        sections.append("\n".join(lines))

    return "\n\n".join(sections)


def fetch_ddl_context(
    schema: str = "SCHEMARAG",
    exclude_tables: frozenset[str] = frozenset(),
) -> str:
    """
    Build a DDL summary string for all schema tables suitable for use
    as a baseline system prompt context.

    Includes: table name, column names, data types, PK/FK indicators,
    and column comments — everything a standard NL2SQL tool would have,
    but none of the graph-derived annotations.
    """
    table_names = get_all_table_names(schema=schema, exclude_tables=exclude_tables)
    sections: list[str] = []

    for table_name in sorted(table_names):
        info = get_table_info(table_name, schema=schema)
        lines: list[str] = [f"TABLE: {info.table_name}"]

        for col in info.columns:
            parts = [f"  {col.name}  {col.data_type}"]
            if col.name in info.pk_columns:
                parts.append("PK")
            fk_tables = [ref_table for col_name, ref_table in info.fk_refs if col_name == col.name]
            if fk_tables:
                parts.append(f"FK→{fk_tables[0]}")
            if not col.nullable:
                parts.append("NOT NULL")
            line = "  ".join(parts)
            if col.comments:
                line += f"  -- {col.comments}"
            lines.append(line)

        sections.append("\n".join(lines))

    return "\n\n".join(sections)
