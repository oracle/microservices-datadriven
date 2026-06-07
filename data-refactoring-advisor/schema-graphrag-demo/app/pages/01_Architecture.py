"""Copyright (c) 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl."""

"""
Page 1 — Architecture overview with animated pipeline diagram.
"""
import streamlit as st

st.set_page_config(page_title="Architecture", layout="wide")
st.title("Pipeline Architecture")

st.markdown("""
## SchemaRAG Pipeline

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         ORACLE AUTONOMOUS DATABASE                          │
│                                                                              │
│  ┌──────────────┐    ┌──────────────────┐    ┌───────────────────────────┐ │
│  │  ~70 University│   │  SQL Tuning Set   │    │   NetworkX + Louvain      │ │
│  │  Tables       │───▶│  UNIV_WORKLOAD    │───▶│   10 Communities          │ │
│  │  ~1M rows     │    │  400+ queries     │    │   5 Bridge/Hub tables     │ │
│  └──────────────┘    └──────────────────┘    └───────────┬───────────────┘ │
│                                                            │                 │
│                                               ┌────────────▼──────────────┐ │
│                                               │  Annotation Generator     │ │
│                                               │  ① IN_COMMUNITY           │ │
│                                               │  ② IS_HUB                 │ │
│                                               │  ③ JOINS_WITH             │ │
│                                               │  ④ HIGH/MEDIUM/LOW AFFIN  │ │
│                                               │  ⑤ BRIDGES                │ │
│                                               │  ⑥ JOINS_PATH chains      │ │
│                                               └────────────┬──────────────┘ │
│                                                            │                 │
│  ┌──────────────────────────────────────────────┐         │                 │
│  │  SCHEMA_EMBEDDINGS          (annotated)       │◀────────┘                 │
│  │  SCHEMA_EMBEDDINGS_BASELINE (plain metadata)  │    OCI GenAI             │
│  │  VECTOR(1024, FLOAT32) — Cohere embed-v3.0    │    Cohere embed-v3.0     │
│  └──────────────────────┬───────────────────────┘                           │
│                          │  VECTOR_DISTANCE cosine                           │
│  NL Question ───────────▶│  top-8 tables                                    │
│                          │                                                   │
│  ┌───────────────────────▼───────────────────────┐                          │
│  │  Select AI + OCI GenAI                        │                          │
│  │  meta.llama-3.1-70b-instruct                  │                          │
│  │  Annotations injected as context comments     │                          │
│  │  DBMS_CLOUD_AI.GENERATE(action=>'runsql')     │                          │
│  └───────────────────────────────────────────────┘                          │
└────────────────────────────────────────────────────────────────────────────┘
```
""")

st.subheader("Key Technical Choices")

col1, col2, col3 = st.columns(3)

with col1:
    st.markdown("""
**Database**
- Oracle Autonomous Database
- Wallet-based mTLS connection
- ~70 university tables, ~1M rows
- SQL Tuning Sets (DBMS_SQLTUNE)
""")

with col2:
    st.markdown("""
**Embeddings & Search**
- OCI GenAI via DBMS_VECTOR_CHAIN
- Cohere embed-english-v3.0 (1024 dims)
- VECTOR(1024, FLOAT32) column
- VECTOR_DISTANCE cosine similarity
""")

with col3:
    st.markdown("""
**SQL Generation**
- Oracle Select AI
- meta.llama-3.1-70b-instruct
- Annotations injected as context
- All-Oracle stack — nothing leaves tenancy
""")

st.subheader("Community Structure")

community_data = {
    "RegistrarCore": ["STU_MST", "ENRL_REC", "GRD_HIST", "ACAD_HIST", "TERM_TBL", "ACAD_STAT_TBL", "STUDENT_PROFILE", "XFER_INST_MAP"],
    "Curriculum": ["CRS_CAT", "CRS_SECT", "DEPT_TBL", "INSTR_TBL", "ROOM_INVT", "CRS_PREREQ", "CLASS_SCHED", "SCHED_OPTIM_WRK"],
    "FinancialAid": ["FINANCIAL_AID_APPLICATION", "FA_AWARD_HISTORY", "SCHOLARSHIP_POOL", "LOAN_DISBURSEMENT", "NEED_ANALYSIS_RESULT", "AID_PACKAGING_RULE", "PELL_ELIGIBILITY_TBL", "STU_FA_XREF"],
    "Bursar": ["BURS_STUDENT_ACCOUNT", "BURS_CHARGE_LINE", "BURS_PAYMENT", "BURS_TUITION_RATE", "BURS_BILLING_PERIOD", "BURS_HOLD_CODE", "BURS_INSTALLMENT_PLAN", "BURS_REFUND_REQUEST", "BURS_STUDENT_HOLD", "TUTN_APPEAL_WRK"],
    "HousingDining": ["HSG_ROOM_INVENTORY", "HSG_ROOM_ASSIGNMENT", "HSG_CONTRACT", "HSG_WAITLIST_WRK", "DINING_PLAN", "DINING_TRANSACTION", "DINING_LOCATION"],
    "Research": ["RESEARCH_PROJECT", "GRANT_TBL", "IRB_PROTOCOL", "FACULTY_APPT", "PUBLICATION_TBL", "GRANT_ALLOC_WRK"],
    "StudentServices": ["ADVISOR_ASSIGN", "ADVISING_NOTE", "CAREER_EMPLOYER", "CAREER_PLACEMENT", "DISABILITY_ACCOM", "TUTORING_SESSION"],
    "Compliance": ["FERPA_CONSENT_LOG", "DEGREE_AUDIT_WRK", "RETENTION_FLAG", "ACAD_EXCEPTION_WRK", "ACCRED_METRIC_TBL"],
    "HR": ["STAFF_HR_XREF", "HR_POSITION", "HR_APPOINTMENT"],
    "Legacy": ["PS_STDNT_ENRL", "PS_CLASS_TBL", "PS_ACAD_PLAN", "OLD_GRADE_ARCH", "LEGACY_CRS_TBL", "PS_TERM_TBL", "PS_STDNT_DEGR"],
}

bridges = {"STU_FA_XREF", "STAFF_HR_XREF", "ACAD_EXCEPTION_WRK", "GRANT_ALLOC_WRK", "ENRL_REC"}

cols = st.columns(4)
for i, (community, tables) in enumerate(community_data.items()):
    with cols[i % 4]:
        st.markdown(f"**{community}**")
        for tbl in tables:
            prefix = "🌉 " if tbl in bridges else "   "
            st.markdown(f"{prefix}`{tbl}`")
        st.markdown("")
