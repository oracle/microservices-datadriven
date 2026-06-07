"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Affinity calculation between table pairs.

Formula (from patent):
    static_coeff  = join_count / (sql_t1 + sql_t2 - join_count)
    dynamic_coeff = join_executions / (exec_t1 + exec_t2 - join_executions)
    total_affinity = (static_coeff * 0.5) + (dynamic_coeff * 0.5)

Inputs come from the co-occurrence data extracted from the SQL Tuning Set.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from src.config import settings


@dataclass
class AffinityResult:
    table1: str
    table2: str
    join_count: int           # distinct SQL statements containing both tables
    join_executions: int      # total executions of those SQL statements
    sql_t1: int               # distinct SQL statements referencing table1
    sql_t2: int               # distinct SQL statements referencing table2
    exec_t1: int              # total executions of statements referencing table1
    exec_t2: int              # total executions of statements referencing table2
    static_coeff: float
    dynamic_coeff: float
    total_affinity: float
    affinity_level: str       # HIGH | MEDIUM | LOW | EXCLUDED


def compute_affinity(
    join_count: int,
    join_executions: int,
    sql_t1: int,
    sql_t2: int,
    exec_t1: int,
    exec_t2: int,
) -> tuple[float, float, float]:
    """
    Return (static_coeff, dynamic_coeff, total_affinity).
    Uses Jaccard-style denominators to normalize for table popularity.
    """
    static_denom = sql_t1 + sql_t2 - join_count
    dynamic_denom = exec_t1 + exec_t2 - join_executions

    static_coeff = join_count / static_denom if static_denom > 0 else 0.0
    dynamic_coeff = join_executions / dynamic_denom if dynamic_denom > 0 else 0.0

    total_affinity = (static_coeff * 0.5) + (dynamic_coeff * 0.5)
    return static_coeff, dynamic_coeff, total_affinity


def classify_affinity(total_affinity: float) -> str:
    """
    Map a numeric affinity to the 4 patent-defined levels.
    Thresholds come from settings (default 0.7 / 0.4 / 0.2).
    """
    if total_affinity >= settings.affinity_high_threshold:
        return "HIGH"
    if total_affinity >= settings.affinity_medium_threshold:
        return "MEDIUM"
    if total_affinity >= settings.affinity_low_threshold:
        return "LOW"
    return "EXCLUDED"


def build_affinity_result(
    table1: str,
    table2: str,
    join_count: int,
    join_executions: int,
    sql_t1: int,
    sql_t2: int,
    exec_t1: int,
    exec_t2: int,
) -> AffinityResult:
    """Convenience constructor that computes and classifies in one call."""
    sc, dc, ta = compute_affinity(
        join_count, join_executions, sql_t1, sql_t2, exec_t1, exec_t2
    )
    return AffinityResult(
        table1=table1,
        table2=table2,
        join_count=join_count,
        join_executions=join_executions,
        sql_t1=sql_t1,
        sql_t2=sql_t2,
        exec_t1=exec_t1,
        exec_t2=exec_t2,
        static_coeff=sc,
        dynamic_coeff=dc,
        total_affinity=ta,
        affinity_level=classify_affinity(ta),
    )
