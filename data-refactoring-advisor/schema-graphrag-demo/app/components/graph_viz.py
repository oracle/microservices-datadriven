"""
Pyvis → Streamlit HTML component helper.
Shared by pages that render the interactive graph.
"""
from __future__ import annotations

import streamlit.components.v1 as components


def render_pyvis_html(html: str, height: int = 600) -> None:
    """Render a Pyvis-generated HTML string inside a Streamlit component."""
    components.html(html, height=height, scrolling=False)
