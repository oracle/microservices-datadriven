"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Embed text via OCI GenAI using DBMS_VECTOR_CHAIN.UTL_TO_EMBEDDING inside ADB.

The embedding call runs entirely within the database:
    DBMS_VECTOR_CHAIN.UTL_TO_EMBEDDING(text, json(config))
This means no Python HTTP calls to OCI — the database handles the roundtrip,
and credentials are stored as a named ADB credential (not in .env).

Returns a list[float] (1024 dims for Cohere embed-english-v3.0).
"""
from __future__ import annotations

import array
from typing import Optional

from src.config import settings
from src.db.connection import get_connection


def embed_text(text: str) -> list[float]:
    """
    Embed a single text string via DBMS_VECTOR_CHAIN inside ADB.
    Returns a 1024-element list of floats.
    """
    sql = f"""
        SELECT DBMS_VECTOR_CHAIN.UTL_TO_EMBEDDING(
            :text,
            json('{settings.embed_json}')
        ) AS embedding
        FROM dual
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, text=text)
            row = cur.fetchone()
            if row is None or row[0] is None:
                raise RuntimeError("UTL_TO_EMBEDDING returned NULL — check OCI credential and model config")
            raw = row[0]
            # ADB returns a vector as a Python array or list depending on driver version
            if isinstance(raw, (list, tuple)):
                return [float(x) for x in raw]
            if isinstance(raw, array.array):
                return list(raw)
            # oracledb may return a bytes object for VECTOR type
            raise TypeError(f"Unexpected embedding return type: {type(raw)}")
