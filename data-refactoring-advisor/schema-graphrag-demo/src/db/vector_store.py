# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
CRUD operations on schema embeddings tables.
"""
from __future__ import annotations

import array
from typing import Optional

from src.db.connection import get_connection


def upsert_embedding_row(
    table_name: str,
    community_name: str,
    base_metadata: str,
    augmented_text: str,
    annotation_count: int,
    baseline: bool = False,
    embeddings_table: str = "SCHEMA_EMBEDDINGS",
    embeddings_baseline_table: str = "SCHEMA_EMBEDDINGS_BASELINE",
) -> None:
    """Insert or update the text documents (no embedding yet)."""
    target = embeddings_baseline_table if baseline else embeddings_table
    if baseline:
        sql = f"""
            MERGE INTO {target} t
            USING (SELECT :tbl AS table_name FROM dual) s
            ON (t.table_name = s.table_name)
            WHEN MATCHED THEN UPDATE SET
                base_metadata = :meta
            WHEN NOT MATCHED THEN INSERT
                (table_name, base_metadata, created_at)
            VALUES (:tbl, :meta, SYSTIMESTAMP)
        """
        params = dict(tbl=table_name, meta=base_metadata)
    else:
        sql = f"""
            MERGE INTO {target} t
            USING (SELECT :tbl AS table_name FROM dual) s
            ON (t.table_name = s.table_name)
            WHEN MATCHED THEN UPDATE SET
                community_name   = :comm,
                base_metadata    = :meta,
                augmented_text   = :aug,
                annotation_count = :cnt,
                updated_at       = SYSTIMESTAMP
            WHEN NOT MATCHED THEN INSERT
                (table_name, community_name, base_metadata, augmented_text,
                 annotation_count, created_at, updated_at)
            VALUES (:tbl, :comm, :meta, :aug, :cnt, SYSTIMESTAMP, SYSTIMESTAMP)
        """
        params = dict(
            tbl=table_name, comm=community_name,
            meta=base_metadata, aug=augmented_text, cnt=annotation_count,
        )

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)


def store_vector(
    table_name: str,
    vector: list[float],
    baseline: bool = False,
    embeddings_table: str = "SCHEMA_EMBEDDINGS",
    embeddings_baseline_table: str = "SCHEMA_EMBEDDINGS_BASELINE",
) -> None:
    """Write a pre-computed numpy/list embedding into the VECTOR column."""
    target = embeddings_baseline_table if baseline else embeddings_table
    vec = array.array("f", vector)
    sql = f"""
        UPDATE {target}
        SET embedding   = :vec,
            embedded_at = SYSTIMESTAMP
        WHERE table_name = :tbl
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.setinputsizes(vec=oracledb_vector_type())
            cur.execute(sql, vec=vec, tbl=table_name)


def oracledb_vector_type():
    """Return oracledb vector DB type for bind variable hints."""
    import oracledb
    return oracledb.DB_TYPE_VECTOR


def fetch_all_augmented_texts(
    baseline: bool = False,
    embeddings_table: str = "SCHEMA_EMBEDDINGS",
    embeddings_baseline_table: str = "SCHEMA_EMBEDDINGS_BASELINE",
) -> list[dict]:
    """Return all rows as dicts for display / notebook use."""
    target = embeddings_baseline_table if baseline else embeddings_table
    cols = "table_name, community_name, augmented_text, annotation_count" \
        if not baseline else "table_name, base_metadata"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(f"SELECT {cols} FROM {target} ORDER BY table_name")
            col_names = [d[0].lower() for d in cur.description]
            return [dict(zip(col_names, row)) for row in cur.fetchall()]


def vector_search(
    query_text: str,
    top_k: int = 8,
    baseline: bool = False,
    embeddings_table: str = "SCHEMA_EMBEDDINGS",
    embeddings_baseline_table: str = "SCHEMA_EMBEDDINGS_BASELINE",
) -> list[dict]:
    """
    Embed query_text via OCI GenAI inside ADB and return top-k closest tables.
    Returns list of dicts: table_name, community_name, augmented_text, distance
    """
    from src.config import settings
    target = embeddings_baseline_table if baseline else embeddings_table
    text_col = "base_metadata" if baseline else "augmented_text"
    comm_col = "NULL AS community_name" if baseline else "community_name"

    sql = f"""
        SELECT table_name, {comm_col}, {text_col},
               VECTOR_DISTANCE(embedding,
                   DBMS_VECTOR_CHAIN.UTL_TO_EMBEDDING(:query_text,
                       json('{settings.embed_json}')),
                   COSINE) AS distance
        FROM {target}
        ORDER BY distance ASC
        FETCH FIRST :top_k ROWS ONLY
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, query_text=query_text, top_k=top_k)
            col_names = [d[0].lower() for d in cur.description]
            return [dict(zip(col_names, row)) for row in cur.fetchall()]
