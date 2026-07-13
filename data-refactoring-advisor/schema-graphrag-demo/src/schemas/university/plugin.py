# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""Westfield University schema plugin — fictional 15-year-old university DB with naming chaos."""
from __future__ import annotations

from src.schemas.base import SchemaContext, SchemaPlugin, register

UNIVERSITY_CONTEXT = SchemaContext(
    schema_name="UNIV_SCHEMARAG",
    sts_name="UNIV_WORKLOAD",
    sts_description="Westfield University workload — realistic multi-era join patterns",
    table_names=frozenset({
        # RegistrarCore (Era 1, 2007)
        "STU_MST", "ENRL_REC", "GRD_HIST", "ACAD_HIST", "TERM_TBL", "ACAD_STAT_TBL",
        # Curriculum (Era 1, 2007)
        "CRS_CAT", "CRS_SECT", "DEPT_TBL", "INSTR_TBL", "ROOM_INVT",
        "CRS_PREREQ", "CLASS_SCHED", "SCHED_OPTIM_WRK", "XFER_INST_MAP",
        # FinancialAid (Era 2, 2010)
        "FINANCIAL_AID_APPLICATION", "FA_AWARD_HISTORY", "SCHOLARSHIP_POOL",
        "LOAN_DISBURSEMENT", "NEED_ANALYSIS_RESULT", "AID_PACKAGING_RULE",
        "PELL_ELIGIBILITY_TBL", "STU_FA_XREF",
        # Legacy/PeopleSoft (Era 3, 2013) — zombie tables
        "PS_STDNT_ENRL", "PS_CLASS_TBL", "PS_ACAD_PLAN", "PS_TERM_TBL",
        "PS_STDNT_DEGR", "OLD_GRADE_ARCH", "LEGACY_CRS_TBL",
        # Bursar (Era 4, 2015)
        "BURS_STUDENT_ACCOUNT", "BURS_CHARGE_LINE", "BURS_PAYMENT",
        "BURS_REFUND_REQUEST", "BURS_TUITION_RATE", "BURS_BILLING_PERIOD",
        "BURS_INSTALLMENT_PLAN", "BURS_HOLD_CODE", "BURS_STUDENT_HOLD",
        "TUTN_APPEAL_WRK",
        # HousingDining (Era 5, 2016)
        "HSG_ROOM_INVENTORY", "HSG_ROOM_ASSIGNMENT", "HSG_CONTRACT",
        "HSG_WAITLIST_WRK", "DINING_PLAN", "DINING_TRANSACTION", "DINING_LOCATION",
        # Research (Era 6, 2018)
        "RESEARCH_PROJECT", "GRANT_TBL", "IRB_PROTOCOL", "FACULTY_APPT",
        "PUBLICATION_TBL", "GRANT_ALLOC_WRK",
        # StudentServices (Era 7, 2019)
        "ADVISOR_ASSIGN", "ADVISING_NOTE", "CAREER_EMPLOYER", "CAREER_PLACEMENT",
        "DISABILITY_ACCOM", "TUTORING_SESSION", "STUDENT_PROFILE",
        # HR (Era 7, 2019)
        "STAFF_HR_XREF", "HR_POSITION", "HR_APPOINTMENT",
        # Compliance (Era 8–9, 2020–present)
        "FERPA_CONSENT_LOG", "DEGREE_AUDIT_WRK", "RETENTION_FLAG",
        "ACAD_EXCEPTION_WRK", "ACCRED_METRIC_TBL",
    }),
    nodes_table="UNIV_NODES",
    edges_table="UNIV_EDGES",
    join_paths_table="UNIV_JOIN_PATHS",
    embeddings_table="UNIV_EMBEDDINGS",
    embeddings_baseline_table="UNIV_EMBEDDINGS_BASELINE",
    workload_sql_path="sql/university/03_workload_queries.sql",
    schema_description="~70-table Westfield University schema across 10 communities and 9 naming eras",
    domain_description=(
        "University administration — student enrollment, grades, financial aid, bursar billing, "
        "housing, dining, research grants, academic exceptions, career services, compliance. "
        "Schema accumulated from 2007 to present with 9 distinct naming conventions. "
        "Key bridge tables: STU_FA_XREF (registrar↔financial aid), STAFF_HR_XREF (curriculum↔HR), "
        "ACAD_EXCEPTION_WRK (exceptions for grade changes and withdrawals), "
        "TUTN_APPEAL_WRK (tuition appeals), GRANT_ALLOC_WRK (faculty effort on grants). "
        "Hub tables: ENRL_REC (enrollment, bridges 5 communities), STU_MST (student master). "
        "Zombie tables from cancelled PeopleSoft project: PS_STDNT_ENRL, PS_CLASS_TBL, PS_TERM_TBL."
    ),
)


@register("university")
class UniversityPlugin(SchemaPlugin):
    context: SchemaContext = UNIVERSITY_CONTEXT

    def run_seed(self) -> None:
        from src.schemas.university.seed_data import run_seed
        run_seed()

    def run_workload(self) -> None:
        from src.workload.sts_loader import load_workload
        load_workload(self.context)
