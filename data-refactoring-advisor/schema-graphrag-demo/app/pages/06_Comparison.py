"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Page 6 — Quantitative comparison: annotation impact on retrieval quality.
Shows how annotation enrichment shifts cosine distances for relevant tables.
"""
import streamlit as st
import pandas as pd

st.set_page_config(page_title="Comparison", layout="wide")
st.title("Annotated vs Baseline — Retrieval Comparison")
st.caption(
    "This page shows how annotation enrichment changes the cosine distance ranking "
    "for a given query — bridge tables move UP, unrelated tables move DOWN."
)

DEMO_QUERY = (
    "Which students receiving financial aid have an unpaid bursar balance "
    "greater than their awarded aid amount this semester?"
)


@st.cache_data(ttl=60, show_spinner=False)
def _retrieve_both(nl_query: str, top_k: int):
    from src.db.vector_store import vector_search
    baseline = vector_search(nl_query, top_k=top_k, baseline=True)
    annotated = vector_search(nl_query, top_k=top_k, baseline=False)
    return baseline, annotated


query = st.text_area("Query:", value=DEMO_QUERY, height=80)
top_k = st.slider("Top-K", 4, 20, 10)

if st.button("Run Retrieval Comparison", type="primary"):
    with st.spinner("Running vector search (baseline + annotated)…"):
        try:
            baseline_rows, annotated_rows = _retrieve_both(query, top_k)
        except Exception as exc:
            st.error(f"Error: {exc}")
            st.stop()

    # Build comparison dataframe
    base_map = {r["table_name"]: (i + 1, float(r["distance"])) for i, r in enumerate(baseline_rows)}
    ann_map = {r["table_name"]: (i + 1, float(r["distance"])) for i, r in enumerate(annotated_rows)}

    all_tables = sorted(set(base_map) | set(ann_map))
    data = []
    for tbl in all_tables:
        b_rank, b_dist = base_map.get(tbl, (None, None))
        a_rank, a_dist = ann_map.get(tbl, (None, None))
        rank_change = None
        if b_rank and a_rank:
            rank_change = b_rank - a_rank  # positive = moved up (better)
        data.append({
            "Table": tbl,
            "Baseline Rank": b_rank,
            "Baseline Distance": f"{b_dist:.4f}" if b_dist else "—",
            "Annotated Rank": a_rank,
            "Annotated Distance": f"{a_dist:.4f}" if a_dist else "—",
            "Rank Change": f"+{rank_change}" if rank_change and rank_change > 0 else (str(rank_change) if rank_change else "NEW" if a_rank else "DROPPED"),
        })

    df = pd.DataFrame(data)

    # Highlight bridge tables
    BRIDGE_TABLES = {"STU_FA_XREF", "STAFF_HR_XREF", "ACAD_EXCEPTION_WRK", "GRANT_ALLOC_WRK", "ENRL_REC"}

    def _style_row(row):
        if row["Table"] in BRIDGE_TABLES:
            return ["background-color: #fff3cd"] * len(row)
        return [""] * len(row)

    st.subheader("Rank shift per table")
    st.caption("🟡 = Bridge/hub table")
    st.dataframe(df.style.apply(_style_row, axis=1), use_container_width=True)

    st.markdown("---")
    col1, col2 = st.columns(2)
    with col1:
        st.subheader("Baseline top-10")
        for r in baseline_rows[:10]:
            bridge_marker = " 🌉" if r["table_name"] in BRIDGE_TABLES else ""
            st.markdown(f"{r['table_name']}{bridge_marker} — `{float(r['distance']):.4f}`")
    with col2:
        st.subheader("Annotated top-10")
        for r in annotated_rows[:10]:
            bridge_marker = " 🌉" if r["table_name"] in BRIDGE_TABLES else ""
            st.markdown(f"{r['table_name']}{bridge_marker} — `{float(r['distance']):.4f}`")
