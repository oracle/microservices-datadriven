# Westfield University — Schema Design Document

## Why This Schema Exists

Oracle ERP is fatally over-documented for the SchemaRAG demo. Claude was trained on Oracle's
official technical references, AskTOM, GitHub ERP repositories, and consultant blogs. When asked
about AP invoices it hallucinates `AP_HOLDS_ALL` from training memory, bypassing annotations
entirely. The annotations compete with training data rather than filling a genuine knowledge gap.

A fictional 15-year-old university schema has no training data. Tables are named understandably
(LLM can map query vocabulary to community context) but the specific schema, join paths, crosswalk
tables, and custom control tables are genuinely unknown to any LLM. It must use the annotations.

---

## The Story

Westfield University is a mid-sized state university, founded 1968, with ~22,000 students across
four campuses. Their IT department has been managing the same Oracle database since 2007.

- Seven database administrators have held the primary role
- Three consulting firms left their mark
- One failed ERP implementation left scar tissue that never fully healed
- The schema has ~94 tables
- No two look alike

You can date a table by its naming convention. Every era left a different fingerprint.

---

## The Eras

### Era 1 — The Registrar's System (2007–2010)

The original DBA was a mainframe veteran who came up through COBOL. Eight-character table names,
uppercase, abbreviated. No FK constraints anywhere — referential integrity lived in a PL/SQL
package called `PKG_REG_RULES` that three people have touched and nobody fully understands.
These tables are the heart of the system. Everything else eventually joins back to them.

**Tables:** `STU_MST`, `ENRL_REC`, `GRD_HIST`, `ACAD_HIST`, `TERM_TBL`, `DEPT_TBL`,
`CRS_CAT`, `CRS_SECT`, `INSTR_TBL`, `ROOM_INVT`, `CRS_PREREQ`, `ACAD_STAT_TBL`, `CLASS_SCHED`

**Naming pattern:** 8 chars max, cryptic abbreviations, no comments, no FKs.

### Era 2 — Financial Aid Integration (2010–2013)

Financial aid ran a separate vendor system for a decade. When the vendor sunset it, IT had to
absorb it. A different consulting firm did the integration — they were more verbose. The join from
financial aid back to the registrar's students goes through `STU_FA_XREF`, a crosswalk table added
because the vendor system used SSNs as the primary key and the registrar used generated `STU_ID`
values. The crosswalk has no comment. Its existence is documented in a Word document on a
SharePoint site that requires VPN.

**Tables:** `FINANCIAL_AID_APPLICATION`, `FA_AWARD_HISTORY`, `SCHOLARSHIP_POOL`,
`LOAN_DISBURSEMENT`, `NEED_ANALYSIS_RESULT`, `AID_PACKAGING_RULE`, `PELL_ELIGIBILITY_TBL`,
`STU_FA_XREF`

**Naming pattern:** Fully spelled out, verbose. Crosswalk table with heterogeneous keys.

### Era 3 — The PeopleSoft Attempt (2013–2016)

Westfield contracted with a systems integrator to implement PeopleSoft Campus Solutions. The
project ran 3 years, consumed $4M, and was cancelled 60% complete. What remains: PS_-prefixed
tables with data from 2013–2016, sitting alongside the original registrar tables. A view called
`V_COMBINED_ENRL` was supposed to reconcile `PS_STDNT_ENRL` with `ENRL_REC`. It doesn't always.

The current DBA refers to this period as "the gap years."

**Tables:** `PS_STDNT_ENRL`, `PS_CLASS_TBL`, `PS_ACAD_PLAN`, `PS_TERM_TBL`, `PS_STDNT_DEGR`

**Naming pattern:** PS_ prefix, PeopleSoft conventions. Low affinity with everything active.

### Era 4 — The Bursar Goes Digital (2015–2017)

The bursar's office modernized separately, with a different vendor and a different consulting firm.
Their naming convention uses a `BURS_` prefix and is reasonably descriptive. The join from the
bursar's world back to students uses `STUDENT_NBR` = `STU_MST.STU_ID` — same value, different
column name. This is documented in a comment on `BURS_STUDENT_ACCOUNT` that says:
`-- NOTE: STUDENT_NBR = STU_MST.STU_ID`. That is the entirety of the documentation.

**Tables:** `BURS_STUDENT_ACCOUNT`, `BURS_CHARGE_LINE`, `BURS_PAYMENT`, `BURS_REFUND_REQUEST`,
`BURS_TUITION_RATE`, `BURS_BILLING_PERIOD`, `BURS_INSTALLMENT_PLAN`, `BURS_HOLD_CODE`

**Naming pattern:** `BURS_` prefix, reasonably descriptive. Cross-era key name mismatch.

### Era 5 — Housing and Dining (2016–2018)

Housing had been using spreadsheets. The new housing director demanded a real system. IT built it
internally. It shows. The `_WRK` suffix means "work table" — a staging/control table with
intermediate state. `HSG_WAITLIST_WRK` column names were chosen by whoever was on call that
Thursday. No comment on the table. No FK constraints.

**Tables:** `HSG_ROOM_INVENTORY`, `HSG_ROOM_ASSIGNMENT`, `HSG_CONTRACT`, `HSG_WAITLIST_WRK`,
`DINING_PLAN`, `DINING_TRANSACTION`, `DINING_LOCATION`

**Naming pattern:** `HSG_` prefix for housing, no prefix for dining. First `_WRK` table appears.

### Era 6 — Research Office (2018–2020)

The VP of Research wanted grant tracking in the main Oracle instance. A grad student with DBA
access created the initial tables. A real DBA cleaned them up a year later. The seam is visible:
clean tables alongside one opaque `_WRK` table that the grad student built and nobody restructured.

**Tables (clean):** `RESEARCH_PROJECT`, `GRANT_TBL`, `IRB_PROTOCOL`, `FACULTY_APPT`,
`PUBLICATION_TBL`

**Tables (grad student era):**
```
GRANT_ALLOC_WRK
  GAW_ID            NUMBER       -- surrogate PK
  GAW_GRANT_REF     NUMBER       -- references GRANT_TBL.GRANT_ID. Not declared.
  GAW_FACAPPT_KEY   NUMBER       -- references FACULTY_APPT.FA_APPT_ID. Column name suggests neither.
  GAW_BGT_PERIOD    VARCHAR2(10) -- budget period: FALL/SPRG/SUMR + year (e.g. FALL2023)
  GAW_ALLOC_PCT     NUMBER       -- percentage of effort allocated (0-100)
  GAW_COMMITTED_AMT NUMBER       -- dollar amount committed
  GAW_STATUS        VARCHAR2(1)  -- A/P/C. No comment.
  GAW_CREATED_DT    DATE
```

### Era 7 — Student Services (2019)

Student Affairs demanded tracking for advising, career placement, and disability services.
The IT team hired a junior developer who used reasonable naming conventions but skipped FKs.

`STAFF_HR_XREF` was added because instructors exist in both the registrar system (`INSTR_TBL`)
and the HR payroll system with different surrogate keys. The crosswalk has columns `SHX_INSTR_ID`
and `SHX_HR_EMP_ID`. No comment. No FK.

**Tables:** `ADVISOR_ASSIGN`, `ADVISING_NOTE`, `CAREER_EMPLOYER`, `CAREER_PLACEMENT`,
`DISABILITY_ACCOM`, `TUTORING_SESSION`, `STAFF_HR_XREF`

**Naming pattern:** Mixed — some reasonable, some abbreviated. Second crosswalk table appears.

### Era 8 — COVID and the Contractor (2020–2021)

Spring 2020. Every university scrambled to handle medical withdrawals, incomplete grades, late
drops, and credit/no-credit conversions. Westfield hired a contractor for 6 months to build an
academic exception tracking system. The contractor delivered `ACAD_EXCEPTION_WRK`. It works. It is
completely undocumented. The contractor left. The table has 8,400 rows. It runs the university's
academic exception process for ~3,000 students per year. Nobody has touched the DDL since 2021.

```
ACAD_EXCEPTION_WRK
  AEW_ID         NUMBER          -- surrogate PK, sequence-generated
  AEW_ENRL_KEY   NUMBER          -- "should be" ENRL_REC.ER_ID. Not declared. Not indexed.
  AEW_STAT_CD    VARCHAR2(10)    -- PEND / APRV / DENY / WTHDR
  AEW_TYPE_CD    VARCHAR2(20)    -- WTHDR_MED / WTHDR_PERS / LATE_DROP / GRD_CHNG / INC_EXTND
  AEW_IMPACT_GPA NUMBER          -- projected GPA change; negative = grade removed from calc
  AEW_REVR_ID    NUMBER          -- reviewer. INSTR_TBL.INSTR_ID or DEPT_TBL.DEPT_ID depending on type.
  AEW_DEPT_APRV  VARCHAR2(1)     -- Y/N
  AEW_DEAN_APRV  VARCHAR2(1)     -- Y/N
  AEW_SUBM_DT    DATE
  AEW_DCSN_DT    DATE
  AEW_NOTES      VARCHAR2(2000)  -- free text. Sometimes populated.
```

No table comment. No FK constraints. A Jira ticket to fix the missing index on AEW_ENRL_KEY
was opened in 2021. It is still open.

### Era 9 — Compliance and Reporting (2021–present)

FERPA compliance, accreditation reporting, degree audit, and retention analysis. Mix of new tables
and retrofitted views over existing data. The `TUTN_APPEAL_WRK` table was built by the bursar's
office using the same `_WRK` convention they'd seen in the housing system. `SCHED_OPTIM_WRK` was
built by the scheduling office to handle course conflict resolution.

**Tables:** `FERPA_CONSENT_LOG`, `DEGREE_AUDIT_WRK`, `RETENTION_FLAG`, `ACCRED_METRIC_TBL`,
`TUTN_APPEAL_WRK`, `SCHED_OPTIM_WRK`, `XFER_INST_MAP`

```
TUTN_APPEAL_WRK
  TAW_ID          NUMBER         -- surrogate PK
  TAW_ACCT_REF    NUMBER         -- references BURS_STUDENT_ACCOUNT.ACCT_ID. Not declared.
  TAW_APPEAL_CD   VARCHAR2(20)   -- FIN_HARD / MED_EMRG / SVCE_ERR / SCHL_ERR. No comment.
  TAW_CREDIT_AMT  NUMBER         -- credit amount requested
  TAW_APRVD_AMT   NUMBER         -- credit amount approved (NULL if pending)
  TAW_STAT_FLG    VARCHAR2(1)    -- P/A/D/W. No comment.
  TAW_SUBM_DT     DATE
  TAW_DCSN_DT     DATE
```

`XFER_INST_MAP` maps external transfer institution course codes to internal course equivalencies.
Columns: `XIM_EXT_INST_CD`, `XIM_EXT_CRS_CD`, `XIM_INT_CRS_NBR`, `XIM_EFF_TERM`, `XIM_STAT`.
No FK. The join to `CRS_CAT` is `XIM_INT_CRS_NBR = CRS_CAT.CRS_NBR`. Not obvious.

---

## The 10 Communities (~94 Tables)

| # | Community | Tables | Character |
|---|---|---|---|
| 1 | **RegistrarCore** | STU_MST, ENRL_REC, GRD_HIST, ACAD_HIST, TERM_TBL, ACAD_STAT_TBL, STU_PHONE_TBL, STU_ADDR_TBL, STU_EMAIL_TBL, DEGREE_TBL | Cryptic 8-char names, no comments, no FKs. The foundation. |
| 2 | **Curriculum** | CRS_CAT, CRS_SECT, DEPT_TBL, INSTR_TBL, ROOM_INVT, CRS_PREREQ, CLASS_SCHED, STUDENT_PROFILE, ACAD_HIST | Same era as RegistrarCore, different team. ENRL_REC bridges them. |
| 3 | **FinancialAid** | FINANCIAL_AID_APPLICATION, FA_AWARD_HISTORY, SCHOLARSHIP_POOL, LOAN_DISBURSEMENT, NEED_ANALYSIS_RESULT, AID_PACKAGING_RULE, PELL_ELIGIBILITY_TBL, STU_FA_XREF, ACAD_STAT_TBL | Verbose naming. STU_FA_XREF is the invisible bridge. ACAD_STAT_TBL bridges here via SAP rules. |
| 4 | **Bursar** | BURS_STUDENT_ACCOUNT, BURS_CHARGE_LINE, BURS_PAYMENT, BURS_REFUND_REQUEST, BURS_TUITION_RATE, BURS_BILLING_PERIOD, BURS_INSTALLMENT_PLAN, BURS_HOLD_CODE, STUDENT_HOLDS | BURS_ prefix. STUDENT_HOLDS is a reference table (types), not hold records. |
| 5 | **HousingDining** | HSG_ROOM_INVENTORY, HSG_ROOM_ASSIGNMENT, HSG_CONTRACT, HSG_WAITLIST_WRK, DINING_PLAN, DINING_TRANSACTION, DINING_LOCATION | Internal build. _WRK table is a black box. |
| 6 | **Research** | RESEARCH_PROJECT, GRANT_TBL, IRB_PROTOCOL, FACULTY_APPT, PUBLICATION_TBL, GRANT_ALLOC_WRK | Split quality — clean tables + one opaque _WRK. |
| 7 | **StudentServices** | ADVISOR_ASSIGN, ADVISING_NOTE, CAREER_EMPLOYER, CAREER_PLACEMENT, DISABILITY_ACCOM, TUTORING_SESSION, CAREER_POSTING | Reasonable naming. ADVISING_NOTE bridges to Compliance. |
| 8 | **Compliance** | FERPA_CONSENT_LOG, DEGREE_AUDIT_WRK, RETENTION_FLAG, ACAD_EXCEPTION_WRK, ACCRED_METRIC_TBL, TUTN_APPEAL_WRK, SCHED_OPTIM_WRK | COVID-era additions + FERPA retrofit. Three _WRK tables. |
| 9 | **HR** | STAFF_HR_XREF, HR_POSITION, HR_APPOINTMENT, HR_DEPT_MAP | Minimal — most HR lives in Workday. STAFF_HR_XREF is the key bridge. |
| 10 | **Legacy** | PS_STDNT_ENRL, PS_CLASS_TBL, PS_ACAD_PLAN, PS_TERM_TBL, OLD_GRADE_ARCH, LEGACY_CRS_TBL | Zombie tables. Have historical data. Low affinity with everything active. |

---

## The 10 Design Principles

Each principle has multiple independent instances. If one instance fails in a demo, others work.

### 1. Crosswalk Tables With Heterogeneous Keys (3 instances)

Tables that bridge two systems where the same entity has different surrogate keys on each side.
No FK constraint declared. The join condition is not derivable from column names alone.

| Table | Left side | Right side | Bridges |
|---|---|---|---|
| `STU_FA_XREF` | `SFX_STU_ID` = STU_MST.STU_ID | `SFX_FA_NBR` = FA system key | RegistrarCore ↔ FinancialAid |
| `STAFF_HR_XREF` | `SHX_INSTR_ID` = INSTR_TBL.INSTR_ID | `SHX_HR_EMP_ID` = payroll key | Curriculum ↔ HR |
| `XFER_INST_MAP` | `XIM_INT_CRS_NBR` = CRS_CAT.CRS_NBR | `XIM_EXT_CRS_CD` = external catalog code | RegistrarCore ↔ transfer credit |

**Demo proof:** Any cross-system query fails at baseline (no discoverable join path), succeeds
annotated (JOINS_PATH chain reveals crosswalk table).

### 2. Opaque Control Tables `_WRK` (5 instances across 5 communities)

Tables built for specific operational processes, named with internal conventions, with opaque
column names and no documentation. The `_WRK` suffix signals "work/control table" but reveals
nothing about content.

| Table | Community | Core opaque columns |
|---|---|---|
| `ACAD_EXCEPTION_WRK` | Compliance | AEW_STAT_CD (PEND/APRV/DENY/WTHDR), AEW_TYPE_CD, AEW_IMPACT_GPA |
| `TUTN_APPEAL_WRK` | Bursar | TAW_APPEAL_CD (FIN_HARD/MED_EMRG/SVCE_ERR/SCHL_ERR), TAW_STAT_FLG |
| `GRANT_ALLOC_WRK` | Research | GAW_STATUS (A/P/C), GAW_ALLOC_PCT, GAW_FACAPPT_KEY |
| `HSG_WAITLIST_WRK` | HousingDining | HW_STAT_FLG (P/O/A/C), HW_PRIORITY_NBR, HW_PREF_BLDG |
| `SCHED_OPTIM_WRK` | Compliance/Curriculum | SOW_CONFLICT_CD, SOW_RSLN_STAT, SOW_SECT_REF, SOW_ROOM_REF |

**Demo proof:** Each table provides 2-3 independent NL query angles (see demo query table below).
Five independent paths across five communities — if any one fails, four remain.

### 3. Hub Tables Bridging Multiple Communities (3 hubs)

Tables whose workload position places them at the center of multiple communities.
The IS_HUB annotation and high degree are the only reliable evidence of their centrality.

- **`ENRL_REC`** — degree 18+. Bridges RegistrarCore ↔ Curriculum ↔ FinancialAid ↔ Compliance ↔ HousingDining. The enrollment record is the universal join point — financial aid eligibility, course credit, exception tracking, and housing eligibility all pivot on it.
- **`STU_MST`** — degree 12+. Bridges RegistrarCore ↔ StudentServices ↔ Bursar ↔ HR. Every system that touches a student eventually joins to STU_MST.
- **`FACULTY_APPT`** — degree 8. Bridges Research ↔ Curriculum ↔ HR. A faculty member has a teaching role (Curriculum), a grant role (Research), and a payroll role (HR) — all joined through FACULTY_APPT.

### 4. Community-Name Mismatches (5 tables)

Tables whose names suggest one community but whose workload position places them in another.
The IN_COMMUNITY annotation corrects the naive LLM assumption.

| Table | Naive guess | Actual community | Why |
|---|---|---|---|
| `FACULTY_APPT` | HR or Curriculum | Research | 80% of joins appear in grant queries, not course assignment queries |
| `BURS_HOLD_CODE` | Bursar | Bridges Bursar + Compliance | Degree audit queries join it as often as billing queries |
| `ROOM_INVT` | Facilities | Curriculum | Never queried for maintenance — always queried for course scheduling |
| `ADVISING_NOTE` | StudentServices | Bridges StudentServices + Compliance | FERPA audit queries join it; retention analysis joins it |
| `ACAD_STAT_TBL` | RegistrarCore | Bridges RegistrarCore + FinancialAid | Federal SAP (Satisfactory Academic Progress) rules make it appear in both contexts equally |

`ACAD_STAT_TBL` is the most powerful example. It contains academic standing records
(Good Standing, Probation, Suspension) and sounds purely academic. But because federal
financial aid rules require checking academic standing before disbursement, every financial
aid query joins it. The IN_COMMUNITY annotation correctly places it as a bridge.

### 5. Naming Era Chaos

Demo query chains deliberately cross at least two naming eras. The join condition crossing
eras is the hardest thing to guess from column names alone:

- `AEW_ENRL_KEY = ENRL_REC.ER_ID` — contractor naming meets 2007 mainframe naming
- `STUDENT_NBR = STU_MST.STU_ID` — bursar naming meets registrar naming
- `GAW_FACAPPT_KEY = FACULTY_APPT.FA_APPT_ID` — grad student naming meets clean research naming
- `SFX_FA_NBR → FINANCIAL_AID_APPLICATION.FA_APP_ID` — crosswalk meets verbose naming

### 6. Zombie Table Disambiguation (3 zombies)

Tables from superseded systems that still have historical data, low affinity with active tables,
and names that overlap conceptually with their modern replacement.

| Zombie | Active replacement | Data coverage | Affinity |
|---|---|---|---|
| `PS_STDNT_ENRL` | `ENRL_REC` | 2013–2016 enrollments | LOW (rarely joined together) |
| `OLD_GRADE_ARCH` | `GRD_HIST` | Pre-2009 grades | LOW (different column structure) |
| `LEGACY_CRS_TBL` | `CRS_CAT` | Pre-2007 course catalog | EXCLUDED (never queried together) |

A query about "enrollment trends over the past 15 years" might need both `ENRL_REC` and
`PS_STDNT_ENRL`. The LOW affinity annotation (rather than EXCLUDED) is the signal that
this join, while rare, is valid.

### 7. Excluded Pairs (~15 across communities)

Pairs that never appear together in the workload — including surprising *almost-plausible* pairs
that an LLM might guess but the workload proves wrong.

**Almost-plausible excluded pairs (most interesting for the demo):**
- `TUTN_APPEAL_WRK` ↔ `ACAD_EXCEPTION_WRK` — both exception processes, completely separate offices, never queried together
- `HSG_WAITLIST_WRK` ↔ `FINANCIAL_AID_APPLICATION` — need-based housing seems linked to FA, but these systems don't talk
- `ADVISING_NOTE` ↔ `GRANT_TBL` — faculty advise students AND hold grants, but no query joins these
- `OLD_GRADE_ARCH` ↔ `GRANT_ALLOC_WRK` — grad student context seems plausible; never actually queried together

**Obvious excluded pairs:**
- `DINING_TRANSACTION` ↔ `RESEARCH_PROJECT`
- `HSG_ROOM_INVENTORY` ↔ `LOAN_DISBURSEMENT`
- `PS_STDNT_ENRL` ↔ `GRANT_TBL`

### 8. Four-Hop Chains (5 independent chains)

Each chain crosses multiple communities and requires at least one non-obvious join condition.
A baseline system cannot guess any of these paths from DDL alone.

| Chain | Hops | Demo scenario |
|---|---|---|
| `STU_MST → ENRL_REC → ACAD_EXCEPTION_WRK → BURS_HOLD_CODE` | 4 | Students with approved exceptions still blocked by bursar |
| `STU_MST → STU_FA_XREF → FINANCIAL_AID_APPLICATION → NEED_ANALYSIS_RESULT` | 4 | Honors students with unmet financial need |
| `FACULTY_APPT → GRANT_ALLOC_WRK → RESEARCH_PROJECT → IRB_PROTOCOL` | 4 | Faculty overcommitted on IRB-approved research |
| `ENRL_REC → GRD_HIST → DEGREE_AUDIT_WRK → ACAD_STAT_TBL` | 4 | Near-graduation students with standing flags |
| `STU_MST → ENRL_REC → HSG_WAITLIST_WRK → HSG_ROOM_ASSIGNMENT` | 4 | Students waitlisted but already assigned a room (data quality) |

### 9. Undocumented Code Values

Every `_WRK` and `_XREF` table has code value columns with no comment. Standard Era 1 tables
have partial comments (realistic — the original DBA sometimes documented, sometimes didn't).

| Table | Column | Values | Comment |
|---|---|---|---|
| `ACAD_EXCEPTION_WRK` | `AEW_STAT_CD` | PEND/APRV/DENY/WTHDR | None |
| `ACAD_EXCEPTION_WRK` | `AEW_TYPE_CD` | WTHDR_MED/WTHDR_PERS/LATE_DROP/GRD_CHNG/INC_EXTND | None |
| `TUTN_APPEAL_WRK` | `TAW_APPEAL_CD` | FIN_HARD/MED_EMRG/SVCE_ERR/SCHL_ERR | None |
| `TUTN_APPEAL_WRK` | `TAW_STAT_FLG` | P/A/D/W | None |
| `HSG_WAITLIST_WRK` | `HW_STAT_FLG` | P/O/A/C | None |
| `GRANT_ALLOC_WRK` | `GAW_STATUS` | A/P/C | None |
| `STU_MST` | `STU_STAT_CD` | A/I/W/G | "Student status" — that's all |
| `ENRL_REC` | `ER_STAT` | R/W/D | None (R=Recorded; W=Waitlisted; D=Dropped — not what you'd guess) |
| `GRD_HIST` | `GRD_CD` | A/B/C/D/F/W/I/AU/CR/NC | "Letter grade or status code" — partially helpful |

The partially-documented `GRD_HIST` is realistic. Someone cared enough to add a comment but not
enough to explain that `AU`=Audit, `CR/NC`=Credit/No Credit, or that `W` means Withdrew-from-course
(distinct from `STU_STAT_CD = 'W'` which means Withdrawn-from-university).

### 10. Vocabulary Isolation — 2-3 NL Query Variants Per `_WRK` Table

For each `_WRK` table, define multiple query angles that test different column paths.
If one query's vocabulary finds a baseline shortcut, the other angles don't.

**`ACAD_EXCEPTION_WRK` queries:**
- "Which students have a pending grade change exception with a positive GPA impact?"
- "Show me medical withdrawals submitted this semester that haven't been approved yet"
- "How many incomplete grade extensions are currently under dean's review?"

**`TUTN_APPEAL_WRK` queries:**
- "Which students filed a tuition appeal for financial hardship and were approved?"
- "Show me service error appeals submitted in the last 60 days that are still pending"

**`GRANT_ALLOC_WRK` queries:**
- "Which faculty members are allocated over 100% effort across their active grants?"
- "Show me grants where committed amounts exceed the approved budget for this period"

**`HSG_WAITLIST_WRK` queries:**
- "Which students are still on the housing waitlist after the assignment deadline?"
- "Show me students who were offered housing but never accepted or declined"

---

## Naming Traps (What DDL Cannot Tell You)

### The Synonym Problem — Same Entity, Different Column Names

**Student identity — 6 column names, same value:**
```
STU_MST.STU_ID
ENRL_REC.ER_STU_ID
BURS_STUDENT_ACCOUNT.STUDENT_NBR  -- documented in comment only
FINANCIAL_AID_APPLICATION.FA_STU_KEY
STU_FA_XREF.SFX_STU_ID
ADVISING_NOTE.ADVISEE_ID
```

**Instructor identity — 3 keys, same person:**
```
INSTR_TBL.INSTR_ID         -- registrar's key
FACULTY_APPT.FA_APPT_ID    -- research office's key
STAFF_HR_XREF.SHX_HR_EMP_ID -- payroll key
```

The crosswalk to reconcile instructor keys is `STAFF_HR_XREF`. Without the
`[INSTR_TBL JOINS_WITH STAFF_HR_XREF]` annotation, a cross-system query (teaching load
vs grant effort) produces a SQL error or Cartesian join.

### The Homonym Problem — Same Name, Different Meaning

**`STATUS` on six tables with six different value sets (no comment on any):**

| Table | Values | Meaning |
|---|---|---|
| `FINANCIAL_AID_APPLICATION` | A/D/P | Accepted/Denied/Pending |
| `BURS_STUDENT_ACCOUNT` | C/D/S | Current/Delinquent/Suspended |
| `RESEARCH_PROJECT` | A/C/H | Active/Completed/On Hold |
| `HSG_CONTRACT` | A/E/T | Active/Expired/Terminated |
| `CAREER_PLACEMENT` | P/A/D | Placed/Active Search/Declined |
| `LOAN_DISBURSEMENT` | S/H/R/C | Scheduled/Held/Released/Cancelled |

A query filtering `STATUS = 'A'` against the wrong table returns Accepted FA applications
when you wanted Active research projects.

**"W" means three different things:**

| Table | Column | W means |
|---|---|---|
| `STU_MST` | `STU_STAT_CD` | Withdrawn from the university |
| `ENRL_REC` | `ER_STAT` | Waitlisted for a course (not withdrawn!) |
| `GRD_HIST` | `GRD_CD` | Withdrew from a course (a grade, not a status) |

**"D" also means three things:**
`FINANCIAL_AID_APPLICATION.STATUS = 'D'` → Denied
`ENRL_REC.ER_STAT = 'D'` → Dropped
`BURS_STUDENT_ACCOUNT.STATUS = 'D'` → Delinquent

### Misleading Table Names

| Table | What you'd expect | What it actually is |
|---|---|---|
| `ACAD_HIST` | Authoritative academic history | Reporting snapshot — populated nightly. Live data is in `GRD_HIST`. |
| `STUDENT_PROFILE` | Main student record | Portal display cache — nightly ETL from `STU_MST`. Always one day behind. |
| `CLASS_SCHED` | Course section schedule | Instructor teaching assignments — who teaches what. Course sections are in `CRS_SECT`. |
| `STUDENT_HOLDS` | Students who have holds | Hold type reference table — defines what types of holds exist. Actual hold records are on `BURS_HOLD_CODE`. |

### Looks-Like-FK-But-Isn't

**`ADVISING_NOTE.DEPT_ID`** — looks like a FK to `DEPT_TBL.DEPT_ID`. It's free text copied from
a web form in 2019. Values include "MATH", "Mathematics", "math dept", "Dept of Mathematics".
Never cleaned up. `ADVISING_NOTE` has EXCLUDED affinity with `DEPT_TBL` — the workload correctly
shows they're never joined.

**`GRANT_ALLOC_WRK.GAW_FACAPPT_KEY`** — the column name suggests neither the source table
(`GRANT_TBL`) nor the target table (`FACULTY_APPT.FA_APPT_ID`). The annotation
`[GRANT_ALLOC_WRK JOINS_WITH FACULTY_APPT]` with MEDIUM affinity is the only evidence of the
join.

**`ACAD_EXCEPTION_WRK.AEW_REVR_ID`** — polymorphic. For grade change exceptions it references
`INSTR_TBL.INSTR_ID`. For medical withdrawals it references `DEPT_TBL.DEPT_ID` (the dean's
office). The DDL says nothing about this. The workload shows `ACAD_EXCEPTION_WRK` joining to
both `INSTR_TBL` and `DEPT_TBL` with LOW affinity — the annotation evidence that the FK is
context-dependent.

### The Obvious Join That's Semantically Wrong

`CRS_SECT.DEPT_ID → DEPT_TBL.DEPT_ID` — correct for most courses. For cross-listed courses
(offered by both Computer Science and Mathematics), `CRS_SECT.DEPT_ID` is the *offering*
department. Budget allocation queries use `CRS_CAT.OWNER_DEPT_ID` (the owning department).

Using `CRS_SECT.DEPT_ID` for a budget query produces wrong numbers for ~15% of courses.
The workload captures this: `CRS_CAT.OWNER_DEPT_ID` appears in financial reporting queries,
`CRS_SECT.DEPT_ID` appears in scheduling queries. Their affinity partners are different.
DDL cannot distinguish these two join paths. Annotations can.

---

## Key Demo Queries

15 queries across 8 independent paths. Baseline fails on each. Annotated succeeds.
If any individual query has a vocabulary issue, 14 others remain.

| # | Natural Language Query | WRK/XREF Table | Why Baseline Fails | Expected Annotated Rows |
|---|---|---|---|---|
| 1 | "Students with pending grade change exceptions with positive GPA impact" | ACAD_EXCEPTION_WRK | No GPA impact column on standard tables | ~120 |
| 2 | "Medical withdrawals this semester awaiting approval" | ACAD_EXCEPTION_WRK | No withdrawal type column on ENRL_REC/GRD_HIST | ~85 |
| 3 | "Students with approved exceptions still blocked by a bursar hold" | ACAD_EXCEPTION_WRK + BURS_HOLD_CODE | 4-hop path — no join path in DDL | ~40 |
| 4 | "Incomplete grade extensions under dean's review" | ACAD_EXCEPTION_WRK | Dean approval column doesn't exist on standard tables | ~35 |
| 5 | "Honors students with unmet financial need" | STU_FA_XREF + NEED_ANALYSIS_RESULT | No join path from STU_MST to FA tables | ~200 |
| 6 | "Students receiving merit aid whose SAP status is probation" | STU_FA_XREF + ACAD_STAT_TBL | Wrong STATUS column — ACAD_STAT_TBL community mismatch | ~55 |
| 7 | "Students on financial aid with a Pell grant and a bursar hold" | STU_FA_XREF + PELL_ELIGIBILITY_TBL | No join path to FA from Bursar side | ~70 |
| 8 | "Faculty with over 100% effort committed across active grants" | GRANT_ALLOC_WRK | No effort allocation column on standard tables | ~30 |
| 9 | "Grants where committed amounts exceed budget for current period" | GRANT_ALLOC_WRK | No committed amount / budget period columns | ~25 |
| 10 | "Students on housing waitlist who were already assigned a room" | HSG_WAITLIST_WRK + HSG_ROOM_ASSIGNMENT | HSG_WAITLIST_WRK invisible to baseline | ~15 |
| 11 | "Students offered housing who never responded" | HSG_WAITLIST_WRK | HW_STAT_FLG='O' — column doesn't exist in DDL baseline context | ~30 |
| 12 | "Tuition appeals for medical emergency approved in last 90 days" | TUTN_APPEAL_WRK | No appeal tracking table in baseline context | ~25 |
| 13 | "Service error appeals still pending after 30 days" | TUTN_APPEAL_WRK | TAW_APPEAL_CD, TAW_STAT_FLG invisible to baseline | ~12 |
| 14 | "Transfer students whose external course credits weren't mapped" | XFER_INST_MAP | XFER_INST_MAP invisible; no cross-system join path | ~180 |
| 15 | "Instructors teaching this semester with no HR appointment record" | STAFF_HR_XREF | No join path from INSTR_TBL to HR system | ~40 |

---

## ADB Setup

- New Oracle Autonomous Database instance (separate from ERP-large instance)
- New Oracle user: `UNIV_SCHEMARAG`
- Run `01_create_schema.sql` as ADMIN to create user and tables
- Pipeline tables created by build pipeline: `UNIV_NODES`, `UNIV_EDGES`, `UNIV_JOIN_PATHS`, `UNIV_EMBEDDINGS`, `UNIV_EMBEDDINGS_BASELINE`

## Pipeline Run Order

```bash
# After ADB setup and .env updated with new instance credentials:
python -m src.pipeline.build_pipeline --schema university
# Steps: ddl → seed → sts → extract → community → joinpaths → annotate
# Estimated runtime: 10-15 min (much smaller than ERP-large)
```

## Verification

```bash
# Primary demo query
python -m src.pipeline.query_pipeline \
  "Which students have a pending grade change exception with a positive GPA impact" \
  --schema university --compare --ddl-baseline --count-total --debug-annotations

# Expected:
# Baseline: SQL error (no GPA impact column) or 0 rows
# Annotated: ~120 rows via ACAD_EXCEPTION_WRK discovered through JOINS_PATH from ENRL_REC
```
