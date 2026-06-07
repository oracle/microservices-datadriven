"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Page 2 — Browse tables, columns, and FK relationships.
"""
import streamlit as st
import pandas as pd

st.set_page_config(page_title="Schema Explorer", layout="wide")
st.title("Schema Explorer")


@st.cache_data(ttl=300)
def _load_tables():
    from src.db.schema_inspector import get_all_table_names
    return get_all_table_names()


@st.cache_data(ttl=300)
def _load_table_info(table_name: str):
    from src.db.schema_inspector import get_table_info
    return get_table_info(table_name)


@st.cache_data(ttl=300)
def _load_nodes():
    from src.db.connection import get_connection
    sql = """
        SELECT table_name, community_name, is_bridge, is_hub, hub_degree,
               sql_count, exec_count
        FROM schemarag_nodes
        ORDER BY community_name, table_name
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            cols = [d[0].lower() for d in cur.description]
            return pd.DataFrame(cur.fetchall(), columns=cols)


try:
    tables = _load_tables()
    nodes_df = _load_nodes()

    st.subheader("All 35 Tables")
    st.dataframe(
        nodes_df[["table_name", "community_name", "is_bridge", "is_hub", "hub_degree", "sql_count", "exec_count"]],
        use_container_width=True,
    )

    st.subheader("Table Detail")
    selected = st.selectbox("Select a table", tables)

    if selected:
        info = _load_table_info(selected)

        col1, col2 = st.columns([2, 1])
        with col1:
            st.markdown(f"**Table:** `{info.table_name}`")
            if info.comments:
                st.markdown(f"**Description:** {info.comments}")
            if info.num_rows is not None:
                st.markdown(f"**Estimated rows:** {info.num_rows:,}")

            col_data = []
            for col in info.columns:
                fk_targets = [ref for (c, ref) in info.fk_refs if c == col.name]
                col_data.append({
                    "Column": col.name,
                    "Type": col.data_type,
                    "PK": "✓" if col.name in info.pk_columns else "",
                    "FK→": ", ".join(fk_targets) if fk_targets else "",
                    "Nullable": "Y" if col.nullable else "N",
                    "Comments": col.comments or "",
                })
            st.dataframe(pd.DataFrame(col_data), use_container_width=True)

        with col2:
            # Community membership
            node_row = nodes_df[nodes_df["table_name"] == selected]
            if not node_row.empty:
                row = node_row.iloc[0]
                st.markdown(f"**Community:** `{row['community_name']}`")
                if row["is_bridge"]:
                    st.success("BRIDGE TABLE")
                if row["is_hub"]:
                    st.info(f"HUB TABLE — degree {row['hub_degree']:.1f}")
                st.markdown(f"**SQL count:** {row['sql_count']}")
                st.markdown(f"**Exec count:** {row['exec_count']}")

except Exception as exc:
    st.error(f"Could not connect to ADB: {exc}")
    st.info("Make sure your .env is configured and the build pipeline has been run.")
