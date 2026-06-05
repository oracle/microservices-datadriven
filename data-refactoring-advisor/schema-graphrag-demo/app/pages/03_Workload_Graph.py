"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Page 3 — Interactive 7-community graph using Pyvis.
"""
import streamlit as st
import pandas as pd

st.set_page_config(page_title="Workload Graph", layout="wide")
st.title("Workload Graph — 7 Communities")


# Community → colour mapping (matches plan)
COMMUNITY_COLORS = {
    "PatientCore":       "#4e79a7",
    "MedicationMgmt":    "#f28e2b",
    "ClinicalServices":  "#59a14f",
    "ProviderAdmin":     "#e15759",
    "Financial":         "#76b7b2",
    "QualityCompliance": "#edc948",
    "Facilities":        "#b07aa1",
}


@st.cache_data(ttl=300)
def _load_graph_data():
    from src.db.connection import get_connection
    import pandas as pd

    node_sql = """
        SELECT table_name, community_name, is_bridge, is_hub, hub_degree
        FROM schemarag_nodes
        WHERE community_name IS NOT NULL
    """
    edge_sql = """
        SELECT table_name_1, table_name_2, total_affinity, affinity_level
        FROM schemarag_edges
        WHERE affinity_level <> 'EXCLUDED'
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(node_sql)
            ncols = [d[0].lower() for d in cur.description]
            nodes = pd.DataFrame(cur.fetchall(), columns=ncols)
            cur.execute(edge_sql)
            ecols = [d[0].lower() for d in cur.description]
            edges = pd.DataFrame(cur.fetchall(), columns=ecols)
    return nodes, edges


def _build_pyvis_html(nodes_df, edges_df, affinity_filter: str) -> str:
    from pyvis.network import Network

    net = Network(height="600px", width="100%", bgcolor="#1a1a2e", font_color="white")
    net.set_options("""
    {
      "physics": {
        "forceAtlas2Based": {
          "gravitationalConstant": -50,
          "springLength": 100
        },
        "solver": "forceAtlas2Based",
        "stabilization": {"iterations": 150}
      },
      "interaction": {"hover": true}
    }
    """)

    for _, row in nodes_df.iterrows():
        color = COMMUNITY_COLORS.get(row["community_name"], "#aaaaaa")
        size = 25 if row["is_hub"] else (18 if row["is_bridge"] else 12)
        label = row["table_name"]
        title = (
            f"{row['table_name']}<br>"
            f"Community: {row['community_name']}<br>"
            f"Bridge: {bool(row['is_bridge'])}  Hub: {bool(row['is_hub'])}"
        )
        net.add_node(row["table_name"], label=label, color=color, size=size, title=title)

    levels = {"HIGH", "MEDIUM", "LOW"} if affinity_filter == "ALL" else {affinity_filter}
    width_map = {"HIGH": 4, "MEDIUM": 2, "LOW": 1}
    for _, row in edges_df.iterrows():
        if row["affinity_level"] not in levels:
            continue
        net.add_edge(
            row["table_name_1"],
            row["table_name_2"],
            value=float(row["total_affinity"]),
            width=width_map.get(row["affinity_level"], 1),
            title=f"{row['affinity_level']}: {row['total_affinity']:.2f}",
        )

    return net.generate_html()


try:
    nodes_df, edges_df = _load_graph_data()

    col1, col2 = st.columns([3, 1])
    with col2:
        affinity_filter = st.selectbox(
            "Show affinity level",
            ["ALL", "HIGH", "MEDIUM", "LOW"],
            index=0,
        )
        st.markdown("**Legend**")
        for cname, color in COMMUNITY_COLORS.items():
            st.markdown(
                f'<span style="background:{color};padding:2px 8px;border-radius:4px;color:white">'
                f'{cname}</span>',
                unsafe_allow_html=True,
            )
        st.markdown("")
        st.markdown("⬤ Large = Hub  |  ◉ Medium = Bridge")

    with col1:
        html = _build_pyvis_html(nodes_df, edges_df, affinity_filter)
        st.components.v1.html(html, height=620, scrolling=False)

    st.subheader("Affinity Distribution")
    level_counts = edges_df["affinity_level"].value_counts().rename_axis("Level").reset_index(name="Count")
    st.dataframe(level_counts, use_container_width=False)

except Exception as exc:
    st.error(f"Could not load graph data: {exc}")
    st.info("Run the build pipeline first.")
