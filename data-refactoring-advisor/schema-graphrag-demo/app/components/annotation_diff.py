"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Before/after annotation text viewer component.
Used by pages 4 and 6 to show the annotation enrichment diff.
"""
from __future__ import annotations

import streamlit as st

ANNOTATION_COLORS = {
    "IN_COMMUNITY":   "#4e79a7",
    "IS_HUB":         "#e15759",
    "JOINS_WITH":     "#59a14f",
    "HIGH_AFFINITY":  "#2ca02c",
    "MEDIUM_AFFINITY":"#ff7f0e",
    "LOW_AFFINITY":   "#9467bd",
    "BRIDGES":        "#e15759",
    "JOINS_PATH":     "#1f77b4",
}


def _color_line(line: str) -> str:
    for keyword, color in ANNOTATION_COLORS.items():
        if keyword in line:
            return (
                f'<div style="background:{color}18;border-left:3px solid {color};'
                f'padding:2px 8px;margin:1px 0;font-family:monospace;font-size:12px">'
                f'{line}</div>'
            )
    return f'<div style="font-family:monospace;font-size:12px;padding:2px 8px">{line}</div>'


def render_annotation_diff(base_text: str, aug_text: str) -> None:
    """Render side-by-side before/after annotation comparison."""
    col1, col2 = st.columns(2)
    with col1:
        st.markdown("**Before (plain metadata)**")
        st.text_area("", value=base_text, height=400, disabled=True, key=f"base_{id(base_text)}")
    with col2:
        st.markdown("**After (SchemaRAG)**")
        html = "\n".join(_color_line(line) for line in aug_text.splitlines())
        st.markdown(
            f'<div style="height:400px;overflow-y:auto;border:1px solid #ddd;'
            f'border-radius:4px;padding:8px">{html}</div>',
            unsafe_allow_html=True,
        )
