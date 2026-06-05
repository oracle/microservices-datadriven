"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
SchemaContext dataclass, SchemaPlugin ABC, and plugin registry.

Each schema ships a SchemaPlugin that holds its SchemaContext and implements
run_seed() / run_workload().  The pipeline loads the right plugin at startup
based on the --schema flag.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class SchemaContext:
    """All schema-specific configuration, threaded through every pipeline step."""

    schema_name: str             # Oracle schema owner, e.g. "SCHEMARAG"
    sts_name: str                # SQL Tuning Set name
    sts_description: str         # STS description string
    table_names: frozenset[str]  # Whitelist for STS extraction (upper-cased)
    nodes_table: str             # e.g. "SCHEMARAG_NODES" or "ERP_NODES"
    edges_table: str             # e.g. "SCHEMARAG_EDGES" or "ERP_EDGES"
    join_paths_table: str        # e.g. "SCHEMARAG_JOIN_PATHS" or "ERP_JOIN_PATHS"
    embeddings_table: str        # e.g. "SCHEMA_EMBEDDINGS" or "ERP_EMBEDDINGS"
    embeddings_baseline_table: str
    workload_sql_path: str       # Relative from project root, e.g. "sql/03_workload_queries.sql"
    schema_description: str      # Shown in pipeline banners
    domain_description: str      # Domain context for Claude prompts

    @property
    def infra_tables(self) -> frozenset[str]:
        """Infrastructure table names to exclude from domain-table lists."""
        return frozenset({
            self.nodes_table,
            self.edges_table,
            self.join_paths_table,
            self.embeddings_table,
            self.embeddings_baseline_table,
        })


class SchemaPlugin(ABC):
    """Base class for a schema plugin.  Each schema registers one subclass."""

    context: SchemaContext

    @abstractmethod
    def run_seed(self) -> None: ...

    @abstractmethod
    def run_workload(self) -> None: ...


# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------

REGISTRY: dict[str, type[SchemaPlugin]] = {}


def register(name: str):
    """Class decorator: register a SchemaPlugin under the given name."""
    def decorator(cls: type[SchemaPlugin]) -> type[SchemaPlugin]:
        REGISTRY[name] = cls
        return cls
    return decorator


def get_plugin(name: str) -> SchemaPlugin:
    """Instantiate and return the plugin registered under *name*."""
    if name not in REGISTRY:
        raise ValueError(
            f"Unknown schema: {name!r}.  Available: {sorted(REGISTRY)}"
        )
    return REGISTRY[name]()
