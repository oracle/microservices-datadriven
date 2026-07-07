# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Assign human-readable names to Louvain community IDs.

Strategy: for each community, look at its member tables and match against
known keyword groups. The 10 university communities are hard-coded by their
defining table names; this gives deterministic naming regardless of which
integer ID Louvain assigns.
"""
from __future__ import annotations

from collections import defaultdict

# Canonical community definitions — the set of tables that *define* each community.
# Any member of these sets causes the community to be named accordingly.
_COMMUNITY_SIGNATURES: list[tuple[str, list[str]]] = [

    # -----------------------------------------------------------------------
    # University schema communities (Westfield University, 2007–present)
    # 10 communities across 9 eras of schema evolution. Cryptic 8-char names
    # (RegistrarCore/Curriculum), verbose names (FinancialAid), vendor prefixes
    # (Bursar=BURS_, Legacy=PS_), and _WRK work tables throughout.
    # -----------------------------------------------------------------------
    ("RegistrarCore", [
        "STU_MST", "ENRL_REC", "GRD_HIST", "ACAD_HIST",
        "TERM_TBL", "ACAD_STAT_TBL", "STUDENT_PROFILE", "XFER_INST_MAP",
    ]),
    ("Curriculum", [
        "CRS_CAT", "CRS_SECT", "DEPT_TBL", "INSTR_TBL",
        "ROOM_INVT", "CRS_PREREQ", "CLASS_SCHED", "SCHED_OPTIM_WRK",
    ]),
    ("FinancialAid", [
        "FINANCIAL_AID_APPLICATION", "FA_AWARD_HISTORY", "SCHOLARSHIP_POOL",
        "LOAN_DISBURSEMENT", "NEED_ANALYSIS_RESULT", "AID_PACKAGING_RULE",
        "PELL_ELIGIBILITY_TBL", "STU_FA_XREF",
    ]),
    ("Bursar", [
        "BURS_STUDENT_ACCOUNT", "BURS_CHARGE_LINE", "BURS_PAYMENT",
        "BURS_TUITION_RATE", "BURS_BILLING_PERIOD", "BURS_HOLD_CODE",
        "BURS_INSTALLMENT_PLAN", "BURS_REFUND_REQUEST", "BURS_STUDENT_HOLD",
        "TUTN_APPEAL_WRK",
    ]),
    ("HousingDining", [
        "HSG_ROOM_INVENTORY", "HSG_ROOM_ASSIGNMENT", "HSG_CONTRACT",
        "HSG_WAITLIST_WRK", "DINING_PLAN", "DINING_TRANSACTION", "DINING_LOCATION",
    ]),
    ("Research", [
        "RESEARCH_PROJECT", "GRANT_TBL", "IRB_PROTOCOL",
        "FACULTY_APPT", "PUBLICATION_TBL", "GRANT_ALLOC_WRK",
    ]),
    ("StudentServices", [
        "ADVISOR_ASSIGN", "ADVISING_NOTE", "CAREER_EMPLOYER",
        "CAREER_PLACEMENT", "DISABILITY_ACCOM", "TUTORING_SESSION",
    ]),
    ("Compliance", [
        "FERPA_CONSENT_LOG", "DEGREE_AUDIT_WRK", "RETENTION_FLAG",
        "ACAD_EXCEPTION_WRK", "ACCRED_METRIC_TBL",
    ]),
    ("HR", [
        "STAFF_HR_XREF", "HR_POSITION", "HR_APPOINTMENT",
    ]),
    ("Legacy", [
        "PS_STDNT_ENRL", "PS_CLASS_TBL", "PS_ACAD_PLAN",
        "OLD_GRADE_ARCH", "LEGACY_CRS_TBL", "PS_TERM_TBL", "PS_STDNT_DEGR",
    ]),
]

# Build a reverse lookup: table_name → community_name
_TABLE_TO_COMMUNITY: dict[str, str] = {}
for _name, _tables in _COMMUNITY_SIGNATURES:
    for _tbl in _tables:
        _TABLE_TO_COMMUNITY[_tbl] = _name


def name_communities(partition: dict[str, int]) -> dict[int, str]:
    """
    Given a Louvain partition (table → community_id), return a dict
    mapping community_id → human-readable name.

    Scoring: for each community, count how many of its member tables
    match each canonical community definition. The definition with the
    highest count wins. Ties go to the first match in _COMMUNITY_SIGNATURES.
    """
    # Group tables by community ID
    by_id: dict[int, list[str]] = defaultdict(list)
    for tbl, cid in partition.items():
        by_id[cid].append(tbl.upper())

    community_names: dict[int, str] = {}
    used_names: set[str] = set()

    for cid, tables in sorted(by_id.items()):
        # Score each canonical community against this detected community's tables
        scores: dict[str, int] = defaultdict(int)
        for tbl in tables:
            canonical_name = _TABLE_TO_COMMUNITY.get(tbl)
            if canonical_name:
                scores[canonical_name] += 1

        # Pick the best-scoring canonical name not already used
        best_name = None
        best_score = -1
        for cname, _sigs in _COMMUNITY_SIGNATURES:
            score = scores.get(cname, 0)
            if score > best_score and cname not in used_names:
                best_score = score
                best_name = cname

        if best_name is None or best_score == 0:
            # All canonical names used up or no match — try best scoring name
            # even if already assigned (handles Louvain splitting one community in two)
            for cname, _sigs in _COMMUNITY_SIGNATURES:
                score = scores.get(cname, 0)
                if score > 0 and score > best_score:
                    best_score = score
                    best_name = cname
        if best_name is None or best_score == 0:
            best_name = f"Misc_{cid}"

        community_names[cid] = best_name
        used_names.add(best_name)

    return community_names


def get_community_for_table(table_name: str) -> str:
    """
    Return the expected canonical community name for a table.
    Used by annotation_generator to set IN_COMMUNITY without a live DB lookup.
    """
    return _TABLE_TO_COMMUNITY.get(table_name.upper(), "Unknown")
