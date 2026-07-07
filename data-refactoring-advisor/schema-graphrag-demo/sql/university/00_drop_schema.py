# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Drop all university schema objects from UNIV_SCHEMARAG.

Drops every table, sequence, and index created by 01_create_schema.sql.
Safe to run when objects don't exist (ORA-00942 / ORA-02289 are silently skipped).
Run BEFORE re-running --step ddl for a clean slate.

Usage:
    python sql/university/00_drop_schema.py
"""
from __future__ import annotations

import sys
import os

# Allow running from the project root
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from rich.console import Console
from src.db.connection import get_connection

console = Console()

# ---------------------------------------------------------------------------
# Objects to drop — reverse creation order where it matters
# ---------------------------------------------------------------------------

TABLES = [
    # Infrastructure (drop first — no domain data)
    "UNIV_WORKLOAD",
    "UNIV_EMBEDDINGS_BASELINE",
    "UNIV_EMBEDDINGS",
    "UNIV_JOIN_PATHS",
    "UNIV_EDGES",
    "UNIV_NODES",

    # Compliance / Era 8-9
    "ACAD_EXCEPTION_WRK",
    "TUTN_APPEAL_WRK",
    "DEGREE_AUDIT_WRK",
    "RETENTION_FLAG",
    "FERPA_CONSENT_LOG",
    "ACCRED_METRIC_TBL",

    # HR / Era 7
    "HR_APPOINTMENT",
    "HR_POSITION",
    "STAFF_HR_XREF",

    # StudentServices / Era 7
    "TUTORING_SESSION",
    "DISABILITY_ACCOM",
    "CAREER_PLACEMENT",
    "CAREER_EMPLOYER",
    "ADVISING_NOTE",
    "ADVISOR_ASSIGN",
    "STUDENT_PROFILE",

    # Research / Era 6
    "GRANT_ALLOC_WRK",
    "PUBLICATION_TBL",
    "FACULTY_APPT",
    "IRB_PROTOCOL",
    "GRANT_TBL",
    "RESEARCH_PROJECT",

    # HousingDining / Era 5
    "HSG_WAITLIST_WRK",
    "DINING_TRANSACTION",
    "DINING_PLAN",
    "DINING_LOCATION",
    "HSG_CONTRACT",
    "HSG_ROOM_ASSIGNMENT",
    "HSG_ROOM_INVENTORY",

    # Bursar / Era 4
    "BURS_STUDENT_HOLD",
    "BURS_INSTALLMENT_PLAN",
    "BURS_REFUND_REQUEST",
    "BURS_PAYMENT",
    "BURS_CHARGE_LINE",
    "BURS_BILLING_PERIOD",
    "BURS_TUITION_RATE",
    "BURS_HOLD_CODE",
    "BURS_STUDENT_ACCOUNT",

    # Legacy / Era 3
    "LEGACY_CRS_TBL",
    "OLD_GRADE_ARCH",
    "PS_STDNT_DEGR",
    "PS_ACAD_PLAN",
    "PS_TERM_TBL",
    "PS_CLASS_TBL",
    "PS_STDNT_ENRL",

    # FinancialAid / Era 2
    "STU_FA_XREF",
    "PELL_ELIGIBILITY_TBL",
    "AID_PACKAGING_RULE",
    "NEED_ANALYSIS_RESULT",
    "LOAN_DISBURSEMENT",
    "SCHOLARSHIP_POOL",
    "FA_AWARD_HISTORY",
    "FINANCIAL_AID_APPLICATION",

    # Curriculum / Era 1
    "SCHED_OPTIM_WRK",
    "XFER_INST_MAP",
    "CLASS_SCHED",
    "CRS_PREREQ",
    "CRS_SECT",
    "CRS_CAT",
    "ROOM_INVT",
    "INSTR_TBL",
    "DEPT_TBL",

    # RegistrarCore / Era 1 (core tables last)
    "ACAD_STAT_TBL",
    "ACAD_HIST",
    "GRD_HIST",
    "ENRL_REC",
    "TERM_TBL",
    "STU_MST",
]

SEQUENCES = [
    "SEQ_STU_ID",
    "SEQ_ENRL_ID",
    "SEQ_GRD_HIST",
    "SEQ_ACAD_HIST",
    "SEQ_AS_ID",
    "SEQ_SECT_ID",
    "SEQ_INSTR_ID",
    "SEQ_ROOM_ID",
    "SEQ_DEPT_ID",
    "SEQ_CS_ID",
    "SEQ_PREREQ_ID",
]

_SKIP_CODES = {
    -942,   # ORA-00942: table or view does not exist
    -2289,  # ORA-02289: sequence does not exist
    -1418,  # ORA-01418: specified index does not exist
}


def _safe_drop(cur, ddl: str) -> bool:
    """Execute a DROP statement. Returns True if dropped, False if not found."""
    try:
        cur.execute(ddl)
        return True
    except Exception as exc:  # noqa: BLE001
        code = getattr(exc, "args", [None])[0]
        if hasattr(code, "code"):
            code = code.code
        if isinstance(code, int) and code in _SKIP_CODES:
            return False
        # Unexpected error — re-raise with context
        raise RuntimeError(f"Unexpected error executing: {ddl}\n  {exc}") from exc


def main() -> None:
    console.rule("[bold red]University Schema — DROP ALL OBJECTS")
    console.print("[dim]Connecting as UNIV_SCHEMARAG…[/dim]\n")

    tables_dropped = tables_skipped = 0
    seqs_dropped = seqs_skipped = 0

    with get_connection() as conn:
        with conn.cursor() as cur:

            console.print("[bold]Dropping tables…[/bold]")
            for table in TABLES:
                dropped = _safe_drop(cur, f"DROP TABLE {table} PURGE")
                if dropped:
                    tables_dropped += 1
                    console.print(f"  [green]DROP TABLE {table}[/green]")
                else:
                    tables_skipped += 1
                    console.print(f"  [dim]SKIP {table} (not found)[/dim]")

            console.print("\n[bold]Dropping sequences…[/bold]")
            for seq in SEQUENCES:
                dropped = _safe_drop(cur, f"DROP SEQUENCE {seq}")
                if dropped:
                    seqs_dropped += 1
                    console.print(f"  [green]DROP SEQUENCE {seq}[/green]")
                else:
                    seqs_skipped += 1
                    console.print(f"  [dim]SKIP {seq} (not found)[/dim]")

        conn.commit()

    console.print()
    console.rule("[bold green]Drop complete")
    console.print(
        f"Tables:    [green]{tables_dropped} dropped[/green] / [dim]{tables_skipped} not found[/dim]\n"
        f"Sequences: [green]{seqs_dropped} dropped[/green] / [dim]{seqs_skipped} not found[/dim]"
    )
    console.print("\n[bold]Ready to re-run:[/bold]")
    console.print("  python -m src.pipeline.build_pipeline --schema university --step ddl")


if __name__ == "__main__":
    main()
