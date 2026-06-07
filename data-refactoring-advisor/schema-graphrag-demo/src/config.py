"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Centralised configuration — reads from .env via pydantic-settings.
All modules import settings from here; never read os.environ directly.
"""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── ADB connection ────────────────────────────────────────────────────────
    adb_dsn: str = "myadb_high"
    adb_user: str = "schemarag"
    adb_password: str
    adb_wallet_location: str = ""   # leave empty for local/Docker (no wallet needed)
    adb_wallet_password: str = ""  # wallet download password (ewallet.pem passphrase)
    adb_admin_user: str = "admin"    # "admin" for ADB, "SYSTEM" for Docker/local
    adb_admin_password: str = ""   # needed for STS cursor-cache load (must run as ADMIN)

    # ── Claude (NL2SQL) ───────────────────────────────────────────────────────
    anthropic_api_key: str = ""
    anthropic_model: str = "claude-opus-4-6"
    anthropic_retrieval_model: str = "claude-haiku-4-5-20251001"

    # ── Pipeline tuning ───────────────────────────────────────────────────────
    seed_random_state: int = 42
    community_random_state: int = 42

    affinity_high_threshold: float = 0.6
    affinity_medium_threshold: float = 0.3
    affinity_low_threshold: float = 0.1

    join_path_min_occurrences: int = 5
    hub_degree_threshold: int = 4
    top_k_retrieval: int = 8

    # ── Derived helpers ───────────────────────────────────────────────────────
    @property
    def wallet_path(self) -> Path:
        return Path(self.adb_wallet_location)


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()


# Convenience alias used throughout the project
settings = get_settings()
