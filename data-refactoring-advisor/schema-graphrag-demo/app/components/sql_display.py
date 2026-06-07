"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
SQL display helpers — syntax highlighting + missing-table annotation.
"""
from __future__ import annotations

import streamlit as st


def display_sql(
    sql: str,
    missing_tables: list[str] | None = None,
    label: str = "Generated SQL",
) -> None:
    """
    Render SQL with syntax highlighting.
    If `missing_tables` is provided, show a warning callout listing them.
    """
    st.markdown(f"**{label}**")
    st.code(sql, language="sql")

    if missing_tables:
        st.warning(
            f"Missing tables (needed for correct results): "
            + ", ".join(f"`{t}`" for t in missing_tables)
        )
