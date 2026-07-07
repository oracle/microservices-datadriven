# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Oracle ADB connection pool using wallet-based mTLS.
All other modules call get_connection() as a context manager.
"""
from __future__ import annotations

import contextlib
from typing import Generator

import oracledb

from src.config import settings

_pool: oracledb.ConnectionPool | None = None
_pool_user: str | None = None


def _init_pool(user: str | None = None) -> oracledb.ConnectionPool:
    kwargs: dict = dict(
        user=user or settings.adb_user,
        password=settings.adb_password,
        dsn=settings.adb_dsn,
        min=1,
        max=5,
        increment=1,
    )
    if settings.adb_wallet_location:
        kwargs["config_dir"] = str(settings.wallet_path)
        kwargs["wallet_location"] = str(settings.wallet_path)
        if settings.adb_wallet_password:
            kwargs["wallet_password"] = settings.adb_wallet_password
    return oracledb.create_pool(**kwargs)


def reset_pool(user: str) -> None:
    """
    Close the existing connection pool and reinitialize it as *user*.

    Call this once at the start of any pipeline that connects as a schema-specific
    user (e.g. UNIV_SCHEMARAG) rather than the global ADB_USER from .env.
    The schema user password is always settings.adb_password (set by --step user).
    """
    global _pool, _pool_user
    if _pool is not None:
        try:
            _pool.close(force=True)
        except Exception:  # noqa: BLE001
            pass
        _pool = None
    _pool_user = user.upper()
    _pool = _init_pool(user=_pool_user)


def get_pool() -> oracledb.ConnectionPool:
    global _pool
    if _pool is None:
        _pool = _init_pool()
    return _pool


@contextlib.contextmanager
def get_connection() -> Generator[oracledb.Connection, None, None]:
    """Yield a connection from the pool; auto-commit on clean exit."""
    pool = get_pool()
    conn = pool.acquire()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        pool.release(conn)


def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.close()
        _pool = None
