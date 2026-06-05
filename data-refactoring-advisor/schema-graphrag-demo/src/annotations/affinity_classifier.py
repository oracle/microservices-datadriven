"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Map numeric affinity scores to the 4 patent-defined levels.

This module is intentionally thin — it delegates to
workload.affinity_calculator so the threshold values remain in one place
(settings.py → .env). Kept as a separate file so the annotations package
has a clean internal import that does not pull in workload dependencies
when only classification is needed.
"""
from __future__ import annotations

from src.workload.affinity_calculator import classify_affinity  # re-export

__all__ = ["classify_affinity"]
