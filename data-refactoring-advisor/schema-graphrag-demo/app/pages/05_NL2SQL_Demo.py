# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Page 5 — THE WOW PAGE: NL → SQL side-by-side comparison.

Standard RAG (baseline) vs SchemaRAG (annotated), showing:
- Which tables were retrieved
- The generated SQL
- Actual query results (row count)
"""
import streamlit as st
import pandas as pd

st.set_page_config(page_title="NL2SQL Demo", layout="wide")
st.title("NL2SQL Demo — The Wow Page")
st.caption("Same question. Same LLM. Radically different results.")

DEMO_QUERIES = {
    "Demo 1 — Financial Aid ↔ Bursar (Bridge: STU_FA_XREF)": (
        "Which students receiving financial aid have an unpaid bursar balance "
        "greater than their awarded aid amount this semester?"
    ),
    "Demo 2 — Instructor Overload + Prerequisites (Opaque columns)": (
        "Which instructors are teaching more than three sections this term "
        "and have at least one section that is a prerequisite for another course they teach?"
    ),
    "Demo 3 — Retention Flags + Advising + Bursar Holds (Cross-community)": (
        "Show students flagged for academic retention intervention who also have "
        "active bursar holds and no advising appointment in the past 60 days"
    ),
    "Demo 4 — Grant Effort + Faculty Appointments (Concept mismatch)": (
        "Which faculty members have grant effort allocations exceeding their "
        "contracted appointment percentage this academic year?"
    ),
    "Demo 5 — Financial Aid Holds Blocking Graduation Audit (5-way cross-community)": (
        "Which students on financial aid probation have active bursar holds, "
        "a pending degree audit, and unresolved academic exceptions blocking their graduation?"
    ),
    "Custom query": "",
}


@st.cache_data(ttl=60, show_spinner=False)
def _run_comparison(nl_query: str, top_k: int):
    from src.pipeline.query_pipeline import run_comparison
    return run_comparison(nl_query, top_k=top_k, max_result_rows=200)


# ── Controls ─────────────────────────────────────────────────────────────────
demo_choice = st.selectbox("Select a demo query:", list(DEMO_QUERIES.keys()))

if demo_choice == "Custom query":
    nl_query = st.text_area("Enter your question:", height=80, placeholder="Ask a question about the university data…")
else:
    nl_query = DEMO_QUERIES[demo_choice]
    st.text_area("Query:", value=nl_query, height=80, disabled=True, key="nl_display")

top_k = st.slider("Top-K tables to retrieve", min_value=4, max_value=15, value=8)

run_btn = st.button("Run Comparison", type="primary", disabled=not nl_query.strip())

# ── Results ───────────────────────────────────────────────────────────────────
if run_btn and nl_query.strip():
    with st.spinner("Running both pipelines…"):
        try:
            baseline_result, annotated_result = _run_comparison(nl_query.strip(), top_k)
        except Exception as exc:
            st.error(f"Pipeline error: {exc}")
            st.stop()

    left, right = st.columns(2)

    def _render_result_panel(col, result, label: str, good: bool):
        icon = "✅" if good else "❌"
        color = "green" if good else "red"
        with col:
            st.markdown(f"### {icon} {label}")

            # Tables retrieved
            st.markdown("**Tables retrieved:**")
            retrieved_names = [r["table_name"] for r in result.retrieved_tables]
            for tbl in retrieved_names:
                marker = "← BRIDGE" if not result.baseline and any(
                    "BRIDGES" in str(r.get("augmented_text", "")) and r["table_name"] == tbl
                    for r in result.retrieved_tables
                ) else ""
                st.markdown(f"  `{tbl}` {marker}")

            # SQL
            st.markdown("**Generated SQL:**")
            st.code(result.generated_sql, language="sql")

            # Results
            if result.sql_valid:
                st.markdown(f"**Results:** :{color}[{result.row_count} rows]")
                if result.row_count > 0 and result.columns:
                    df = pd.DataFrame(result.rows, columns=result.columns)
                    st.dataframe(df.head(20), use_container_width=True)
                elif result.row_count == 0:
                    st.warning("0 rows returned — query may be missing join tables.")
            else:
                st.error(f"SQL error: {result.sql_error}")

    _render_result_panel(left, baseline_result, "Standard RAG (no annotations)", good=False)
    _render_result_panel(right, annotated_result, "SchemaRAG (annotated)", good=True)

    # Delta summary
    st.markdown("---")
    delta = annotated_result.row_count - baseline_result.row_count
    tables_gained = set(r["table_name"] for r in annotated_result.retrieved_tables) - \
                    set(r["table_name"] for r in baseline_result.retrieved_tables)

    col1, col2, col3 = st.columns(3)
    col1.metric("Standard RAG rows", baseline_result.row_count)
    col2.metric("SchemaRAG rows", annotated_result.row_count, delta=delta)
    col3.metric("Extra tables found by GraphRAG", len(tables_gained))

    if tables_gained:
        st.info(
            f"SchemaRAG additionally retrieved: "
            + ", ".join(f"`{t}`" for t in sorted(tables_gained))
            + " — via BRIDGES / JOINS_PATH annotations."
        )
