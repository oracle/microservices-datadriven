# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Basic SQL parse-check before executing Select AI output.

Uses sqlglot to detect obvious syntax errors without running the query.
This is a best-effort guard — execution errors are still possible and
are caught by the caller.
"""
from __future__ import annotations

import sqlglot


def is_valid_sql(sql: str) -> tuple[bool, str]:
    """
    Return (True, "") if the SQL parses without errors,
    or (False, error_message) if sqlglot flags a problem.
    """
    try:
        statements = sqlglot.parse(sql, dialect="oracle", error_level=sqlglot.ErrorLevel.RAISE)
        if not statements or all(s is None for s in statements):
            return False, "No parseable statement found"
        return True, ""
    except sqlglot.errors.ParseError as exc:
        return False, str(exc)


def extract_table_references(sql: str) -> list[str]:
    """
    Return a list of table names referenced in the SQL statement.
    Useful for the demo UI to highlight which tables were used.
    """
    tables: set[str] = set()
    try:
        for stmt in sqlglot.parse(sql, dialect="oracle"):
            if stmt is None:
                continue
            for tbl in stmt.find_all(sqlglot.exp.Table):
                name = tbl.name
                if name:
                    tables.add(name.upper())
    except Exception:  # noqa: BLE001
        pass
    return sorted(tables)
