"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
SchemaRAG Demo — Streamlit entry point.

Run with:
    streamlit run app/streamlit_app.py
"""
import streamlit as st

st.set_page_config(
    page_title="SchemaRAG Demo",
    page_icon="🎓",
    layout="wide",
    initial_sidebar_state="expanded",
)

st.title("SchemaRAG Demo")
st.subheader("Graph-Derived Relationship Annotation Embeddings for NL2SQL")

st.markdown("""
### What this demo shows

Traditional vector RAG embeds raw table metadata — column names, types, row counts.
When asked a natural-language question that spans multiple communities, the vector
similarity search retrieves the *directly obvious* tables but **misses bridge tables**
that connect communities, producing SQL with broken or missing joins.

**SchemaRAG** enriches each table's metadata with workload-derived graph annotations
before embedding:

| Annotation type | Example |
|---|---|
| Community membership | `[ENRL_REC IN_COMMUNITY RegistrarCore]` |
| Hub indicator | `[ENRL_REC IS_HUB degree:8.0]` |
| Join indicators | `[ENRL_REC JOINS_WITH STU_MST]` |
| Affinity indicators | `[ENRL_REC HIGH_AFFINITY STU_MST:0.82]` |
| Bridge indicators | `[STU_FA_XREF BRIDGES RegistrarCore:FinancialAid]` |
| Join-path chains | `[ENRL_REC JOINS_PATH STU_MST→ENRL_REC→GRD_HIST]` |

The result: the same NL question retrieves bridge tables via semantic similarity to
their annotations, and the generated SQL is correct.

---

**Navigate** using the sidebar to explore each stage of the pipeline.
""")

st.sidebar.success("Select a page above.")
