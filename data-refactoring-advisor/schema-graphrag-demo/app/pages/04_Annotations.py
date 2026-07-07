# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Page 4 — Annotation explorer: side-by-side before/after diff viewer.
Shows all 4 patent annotation types with colour coding.
"""
import streamlit as st

st.set_page_config(page_title="Annotation Explorer", layout="wide")
st.title("Annotation Explorer")
st.caption("See how SchemaRAG enriches table metadata with graph-derived annotations.")

ANNOTATION_COLORS = {
    "IN_COMMUNITY": "#4e79a7",   # blue
    "IS_HUB":       "#e15759",   # red
    "JOINS_WITH":   "#59a14f",   # green
    "HIGH_AFFINITY":  "#2ca02c",
    "MEDIUM_AFFINITY": "#ff7f0e",
    "LOW_AFFINITY":   "#9467bd",
    "BRIDGES":      "#e15759",   # red
    "JOINS_PATH":   "#1f77b4",   # blue
}


def _color_annotation_line(line: str) -> str:
    """Wrap annotation line in a colored span."""
    for keyword, color in ANNOTATION_COLORS.items():
        if keyword in line:
            return (
                f'<span style="background:{color}22;border-left:3px solid {color};'
                f'padding:2px 6px;display:block;margin:1px 0;font-family:monospace">'
                f'{line}</span>'
            )
    return f'<span style="font-family:monospace">{line}</span>'


@st.cache_data(ttl=300)
def _load_table_list():
    from src.db.schema_inspector import get_all_table_names
    return sorted(get_all_table_names())


@st.cache_data(ttl=60)
def _load_base_metadata(table_name: str) -> str:
    from src.db.connection import get_connection
    sql = "SELECT base_metadata FROM schema_embeddings_baseline WHERE table_name = :tbl"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tbl=table_name)
            row = cur.fetchone()
    return str(row[0]) if row and row[0] else "(no baseline metadata found)"


@st.cache_data(ttl=60)
def _load_augmented_text(table_name: str) -> str:
    from src.db.connection import get_connection
    sql = "SELECT augmented_text, annotation_count FROM schema_embeddings WHERE table_name = :tbl"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tbl=table_name)
            row = cur.fetchone()
    if not row:
        return "(no annotated text found)", 0
    return str(row[0]) if row[0] else "", int(row[1] or 0)


@st.cache_data(ttl=60)
def _load_excluded_tables(table_name: str) -> list[str]:
    """Tables with affinity < 0.2 — excluded from annotations (patent Claim 6)."""
    from src.db.connection import get_connection
    sql = """
        SELECT CASE WHEN table_name_1 = :tbl THEN table_name_2 ELSE table_name_1 END AS other
        FROM schemarag_edges
        WHERE (table_name_1 = :tbl OR table_name_2 = :tbl)
          AND affinity_level = 'EXCLUDED'
        ORDER BY total_affinity DESC
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tbl=table_name)
            return [row[0] for row in cur.fetchall()]


try:
    tables = _load_table_list()

    # Quick-select buttons for the wow tables
    st.markdown("**Quick select (demo tables):**")
    demo_cols = st.columns(6)
    demo_tables = ["ENRL_REC", "STU_FA_XREF", "STAFF_HR_XREF", "DEGREE_AUDIT_WRK", "ACAD_EXCEPTION_WRK", "SCHED_OPTIM_WRK"]
    selected_quick = None
    for i, tbl in enumerate(demo_tables):
        with demo_cols[i]:
            if st.button(tbl):
                selected_quick = tbl

    selected = st.selectbox(
        "Or select any table:",
        tables,
        index=tables.index(selected_quick) if selected_quick and selected_quick in tables else 0,
    )

    base_text = _load_base_metadata(selected)
    aug_text, ann_count = _load_augmented_text(selected)
    excluded = _load_excluded_tables(selected)

    st.markdown(f"**{ann_count} annotation lines** for `{selected}`")

    left_col, right_col = st.columns(2)

    with left_col:
        st.markdown("### ❌ Without SchemaRAG")
        st.markdown("*(plain table metadata only)*")
        st.text_area("Base metadata", value=base_text, height=400, key="base", disabled=True)

    with right_col:
        st.markdown("### ✅ With SchemaRAG")
        st.markdown("*(metadata + all 4 annotation types)*")

        # Render annotation lines with colour coding
        html_parts = []
        for line in aug_text.splitlines():
            stripped = line.strip()
            if stripped.startswith("["):
                html_parts.append(_color_annotation_line(stripped))
            else:
                html_parts.append(f'<span style="font-family:monospace">{line}</span><br>')
        st.markdown("\n".join(html_parts), unsafe_allow_html=True)

    # Annotation type legend
    st.markdown("---")
    legend_cols = st.columns(4)
    legend = [
        ("🟦 Community", "IN_COMMUNITY", "#4e79a7"),
        ("🟥 Bridge/Hub", "BRIDGES / IS_HUB", "#e15759"),
        ("🟩 Join indicators", "JOINS_WITH / JOINS_PATH", "#59a14f"),
        ("🟨 Affinity", "HIGH / MEDIUM / LOW _AFFINITY", "#ff7f0e"),
    ]
    for i, (label, example, _) in enumerate(legend):
        with legend_cols[i]:
            st.markdown(f"**{label}**  \n`{example}`")

    if excluded:
        st.markdown("---")
        st.markdown("### Excluded relationships *(affinity < 0.2 — patent Claim 6)*")
        st.markdown(
            f"`{selected}` has **no annotations** for: "
            + ", ".join(f"`{t}`" for t in excluded[:10])
            + (" …" if len(excluded) > 10 else "")
        )
        st.caption(
            "These table pairs appeared together too rarely in the workload to meet "
            "the minimum affinity threshold. Excluding them prevents noise in the embedding."
        )

except Exception as exc:
    st.error(f"Error loading annotation data: {exc}")
    st.info("Run the build pipeline first to generate annotations.")
