# SchemaRAG — University Schema Scenario Tests

Each test runs the same natural language question through two pipelines side-by-side:

- **Standard RAG (baseline):** The LLM receives only the DDL of the tables it selected — column names, data types, constraints. No join graph. This is how capable NL2SQL tools work today.
- **SchemaRAG (annotated):** The LLM receives the same DDL plus graph-derived annotations: which tables join together, how frequently, which tables are bridges between modules, and proven multi-hop join paths extracted from the actual query workload.

The schema has **zero declared foreign key constraints** — no `REFERENCES` clauses in `CREATE TABLE`, no `ALTER TABLE ADD CONSTRAINT FOREIGN KEY` statements, nothing visible in `ALL_CONSTRAINTS` or `ALL_CONS_COLUMNS`. Every join relationship exists only in application code and query workload history. This is not a contrived condition. FK constraints are routinely absent in large Oracle installations: vendor-delivered schemas commonly delegate referential integrity to application logic or operational processes rather than the database layer, and schemas built by many teams over many years without a strong data modeling discipline accumulate the same pattern through entropy rather than design. The demo audience almost certainly manages schemas that look exactly like this. The demo isn't a contrived edge case — it's Tuesday.

Every join relationship the LLM uses must come either from column name intuition (baseline) or from workload-derived annotations (SchemaRAG).

The university schema spans 55 tables across 10 communities representing 15 years of organic growth at a fictional mid-sized state university. Tables were built by seven DBAs, three consulting firms, and one contractor who left no documentation. Naming conventions change by era: 8-character mainframe-style abbreviations (2007), verbose financial aid names (2010), PeopleSoft PS_ prefixes (2013), BURS_ vendor prefixes (2015), and _WRK contractor tables (2020). No two eras look alike.

---

## Scenario 1 — Opaque Work Table Bridge (Pending Grade Change Exceptions)

**Demonstrates:** A contractor-built exception tracking table (`ACAD_EXCEPTION_WRK`) sits between the student master and enrollment records with no declared foreign key, no index on its join column, and opaque 3-character column name prefixes. The bridge table is invisible to DDL analysis. Without workload-derived join path annotations, the LLM must guess both which table bridges the gap and which column carries the join — and it guesses wrong on both counts.

### The Question

> "Which students have a pending grade change exception with a positive GPA impact?"

This is a **grade exception workflow query** — the kind a registrar's office or department chair runs before a grade change deadline. When a student petitions for a grade correction (a late grade entry, a GPA recalculation, or an instructor error), the academic exception system records the request and projects the GPA impact before approval. The registrar needs to see which pending exceptions would improve a student's GPA, to prioritize review and meet academic calendar deadlines.

The correct answer requires navigating through `ENRL_REC` — the enrollment record table — to reach `ACAD_EXCEPTION_WRK`. There is no path from `STU_MST` directly to `ACAD_EXCEPTION_WRK`; exceptions are keyed to enrollment records, not students. This indirection was not documented when the contractor delivered the table in 2020. The join condition (`AEW_ENRL_KEY = ENRL_REC.ER_ID`) appears only in an internal email thread that no longer exists. The Jira ticket to add an index and a FK comment is still open.

### Command

```bash
python -m src.pipeline.query_pipeline \
  "Which students have a pending grade change exception with a positive GPA impact" \
  --schema university --compare --ddl-baseline --count-total --debug-annotations
```

---

### Standard RAG (baseline) — Missing Bridge Table, Invented Column Name

**Tables selected:** `ACAD_EXCEPTION_WRK, GRD_HIST, STU_MST`

Note: `ENRL_REC` was not selected. The baseline had no evidence it was required. The LLM constructed a JOIN between `ACAD_EXCEPTION_WRK` and `STU_MST` through `ENRL_REC` by inventing an alias — but used `ENRL_KEY` as the join column, a name that does not exist in the schema.

```sql
SELECT s.STU_ID, s.STU_FNM, s.STU_LNM, s.STU_LVL, s.STU_GPA,
       a.AEW_ID, a.AEW_TYPE_CD, a.AEW_STAT_CD, a.AEW_IMPACT_GPA, a.AEW_SUBM_DT, a.AEW_NOTES
FROM UNIV_SCHEMARAG.ACAD_EXCEPTION_WRK a
JOIN UNIV_SCHEMARAG.ENRL_REC e ON e.ENRL_KEY = a.AEW_ENRL_KEY   -- ← invented column name
JOIN UNIV_SCHEMARAG.STU_MST s ON s.STU_ID = e.STU_ID
WHERE a.AEW_TYPE_CD = 'GRD_CHNG'
  AND UPPER(a.AEW_STAT_CD) LIKE '%PEND%'
  AND a.AEW_IMPACT_GPA > 0
ORDER BY a.AEW_IMPACT_GPA DESC
FETCH FIRST 100 ROWS ONLY
```

**Result:** SQL Error — `ORA-00904: "E"."ENRL_KEY": invalid identifier`

The column `ENRL_KEY` does not exist. The actual primary key of `ENRL_REC` is `ER_ID` — a 6-character abbreviated column name consistent with the 2007 mainframe-era naming convention. The LLM correctly deduced that `ENRL_REC` was needed but had no evidence for the column name and constructed a plausible-sounding surrogate. The query cannot execute.

---

### SchemaRAG (annotated) — Correct Bridge, Correct Columns

**Tables selected:** `ACAD_EXCEPTION_WRK, ENRL_REC, GRD_HIST, STU_MST`

Note: `ENRL_REC` was added by SchemaRAG. The annotated Haiku retriever selected it because `ACAD_EXCEPTION_WRK`'s annotation includes `[ACAD_EXCEPTION_WRK JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK]`, making the three-hop chain explicit.

```sql
SELECT
    s.STU_FNM,
    s.STU_LNM,
    s.STU_EMAIL,
    s.STU_LVL,
    s.STU_GPA,
    a.AEW_ID,
    a.AEW_IMPACT_GPA,
    a.AEW_SUBM_DT,
    a.AEW_DEPT_APRV,
    a.AEW_DEAN_APRV,
    a.AEW_NOTES,
    e.ER_TERM_CD,
    e.ER_GRD_CD,
    e.ER_SECT_ID
FROM UNIV_SCHEMARAG.ACAD_EXCEPTION_WRK a
JOIN UNIV_SCHEMARAG.ENRL_REC e
    ON e.ER_ID = a.AEW_ENRL_KEY          -- ← correct: ER_ID is the PK, not ENRL_KEY
JOIN UNIV_SCHEMARAG.STU_MST s
    ON s.STU_ID = e.ER_STU_ID            -- ← correct: ER_STU_ID links enrollment to student
WHERE a.AEW_TYPE_CD = 'GRD_CHNG'
  AND UPPER(a.AEW_STAT_CD) LIKE '%PEND%'
  AND a.AEW_IMPACT_GPA > 0
ORDER BY a.AEW_IMPACT_GPA DESC
FETCH FIRST 100 ROWS ONLY
```

**Result:** 93 rows (total without limit: 93). One row per pending grade change exception with positive GPA impact, showing student name, current GPA, projected GPA improvement, submission date, approval status, and the enrollment term and section the exception applies to.

---

### Why SchemaRAG Wins

**The baseline encountered two independent failures.** It needed to find `ENRL_REC` as the intermediary table, and then correctly name the join column. It failed at both.

**Failure 1 — Missing bridge table.** The baseline selected `ACAD_EXCEPTION_WRK`, `GRD_HIST`, and `STU_MST`. The natural language question mentions students and grade changes — both of those maps to tables in the retriever's index. `ENRL_REC` is not a natural vocabulary match for "grade change exception." The baseline had no workload evidence that exceptions are keyed to enrollment records rather than directly to students. `ACAD_EXCEPTION_WRK.AEW_ENRL_KEY` is an opaque 10-character prefixed column that gives no semantic hint about what it references. The baseline knew a join to student was needed, but had no path.

**Failure 2 — Invented column name.** When the LLM attempted to construct the join via `ENRL_REC` anyway (it included the table in its SQL despite not selecting it), it had no DDL for `ENRL_REC` because that table was not in the retrieved set. It guessed `ENRL_KEY` as the primary key — a reasonable English construction for a table named enrollment record. The actual column is `ER_ID`, the 2007-era mainframe abbreviation. The query fails at execution with ORA-00904.

**SchemaRAG succeeded on both counts.** The annotation on `ACAD_EXCEPTION_WRK` includes `[ACAD_EXCEPTION_WRK JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK]`. This is a workload-extracted three-hop path, meaning the actual application has joined these three tables in this order repeatedly. The retriever selected `ENRL_REC` because the annotation for `ACAD_EXCEPTION_WRK` explicitly named it. Once `ENRL_REC` was in the retrieved set, its DDL was visible — and `ER_ID` and `ER_STU_ID` are unambiguous column names in that context.

**The schema design makes this failure deterministic for the baseline.** `ACAD_EXCEPTION_WRK` was delivered by a contractor in 2020. No FK constraint was declared. No index was added to `AEW_ENRL_KEY`. No column comment documents the join target. The table's name contains "exception" and "work" — neither of which signals the enrollment relationship. A DBA reviewing the DDL alone has no path to the correct query. That path exists only in the workload evidence captured in the STS and surfaced as graph annotations.

**The accounting impact:** A registrar running the baseline query is told no results are available (SQL error) and cannot proceed. The 93 students with pending grade improvements that could affect their academic standing, scholarship eligibility, or graduation clearance remain invisible. Grade change windows are typically one semester long — if the deadline passes, the exception process closes and the correction may require a formal academic appeal committee.

---

### Join Path Illustrations

#### Standard RAG (baseline) — Missing Bridge, Invalid Column

The baseline selects tables from vocabulary match alone. "Grade change" and "students" map correctly, but "enrollment record" as the required intermediary is invisible. The attempted join uses an invented column name.

```
STU_MST
    │
    │  (no direct path to exceptions)
    │
    ▼
ACAD_EXCEPTION_WRK
    │
    │  e.ENRL_KEY = a.AEW_ENRL_KEY  ← ENRL_KEY does not exist
    ▼
ENRL_REC  (not retrieved — no DDL available)
           ORA-00904: "E"."ENRL_KEY": invalid identifier


GRD_HIST  ← retrieved, not used in join chain
ENRL_REC  ← NOT RETRIEVED
           (no FK, no annotation, no vocabulary match for "exception")
```

**Result:** SQL error. Query cannot execute.

---

#### SchemaRAG (annotated) — Three-Hop Chain via ENRL_REC

The `JOINS_PATH` annotation on `ACAD_EXCEPTION_WRK` makes `ENRL_REC` explicit. The retriever selects it; its DDL is visible; the correct columns are used.

```
STU_MST
    │
    │  s.STU_ID = e.ER_STU_ID
    ▼
ENRL_REC  ◄── BRIDGE TABLE (retrieved via JOINS_PATH annotation)
    │  [ACAD_EXCEPTION_WRK JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK]
    │  [ENRL_REC MEDIUM_AFFINITY ACAD_EXCEPTION_WRK:0.22]
    │  [ENRL_REC IS_HUB degree:5.0]
    │
    │  e.ER_ID = a.AEW_ENRL_KEY    ← correct: ER_ID is the primary key
    ▼
ACAD_EXCEPTION_WRK
(AEW_TYPE_CD = 'GRD_CHNG'
 AEW_STAT_CD = 'PEND'
 AEW_IMPACT_GPA > 0)
```

**Result:** 93 rows. Students with pending grade changes that would improve their GPA, with enrollment term, section, and dual-approval status.

---

### Annotations Provided to the LLM

#### `ACAD_EXCEPTION_WRK` — The Invisible Contractor Table

```
[ACAD_EXCEPTION_WRK BRIDGES Bursar:RegistrarCore]
[ACAD_EXCEPTION_WRK JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK]
[ACAD_EXCEPTION_WRK JOINS_PATH ENRL_REC→ACAD_EXCEPTION_WRK→BURS_STUDENT_ACCOUNT]
[ACAD_EXCEPTION_WRK JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK→BURS_STUDENT_ACCOUNT]
[ACAD_EXCEPTION_WRK JOINS_PATH ACAD_EXCEPTION_WRK→ENRL_REC→ACAD_STAT_TBL]
[ACAD_EXCEPTION_WRK JOINS_PATH ACAD_EXCEPTION_WRK→ENRL_REC→GRD_HIST]
[ACAD_EXCEPTION_WRK IN_COMMUNITY RegistrarCore]
[ACAD_EXCEPTION_WRK JOINS_WITH ENRL_REC]
[ACAD_EXCEPTION_WRK MEDIUM_AFFINITY ENRL_REC:0.22]
[ACAD_EXCEPTION_WRK JOINS_WITH STU_MST]
[ACAD_EXCEPTION_WRK LOW_AFFINITY STU_MST:0.14]
[ACAD_EXCEPTION_WRK JOINS_WITH BURS_STUDENT_ACCOUNT]
[ACAD_EXCEPTION_WRK LOW_AFFINITY BURS_STUDENT_ACCOUNT:0.10]
```

The `JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK` annotation is the critical signal. It names `ENRL_REC` explicitly as the required intermediary and proves the ordering: student → enrollment → exception. Without this, there is no discoverable path from DDL alone. The `BRIDGES Bursar:RegistrarCore` annotation gives the table functional identity — it spans the academic records and billing systems, which explains why the annotated side also surfaced bursar join paths for the 4-hop demo query.

#### `ENRL_REC` — The Hub That Connects Everything

```
[ENRL_REC BRIDGES Bursar:RegistrarCore]
[ENRL_REC JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK]
[ENRL_REC JOINS_PATH ENRL_REC→GRD_HIST→DEGREE_AUDIT_WRK]
[ENRL_REC JOINS_PATH ENRL_REC→ACAD_EXCEPTION_WRK→BURS_STUDENT_ACCOUNT]
[ENRL_REC JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK→BURS_STUDENT_ACCOUNT]
[ENRL_REC JOINS_PATH ENRL_REC→CRS_SECT→CRS_CAT]
[ENRL_REC JOINS_PATH ACAD_EXCEPTION_WRK→ENRL_REC→ACAD_STAT_TBL]
[ENRL_REC IN_COMMUNITY RegistrarCore]
[ENRL_REC IS_HUB degree:5.0]
[ENRL_REC JOINS_WITH STU_MST]
[ENRL_REC MEDIUM_AFFINITY STU_MST:0.38]
[ENRL_REC JOINS_WITH GRD_HIST]
[ENRL_REC MEDIUM_AFFINITY GRD_HIST:0.27]
[ENRL_REC JOINS_WITH ACAD_EXCEPTION_WRK]
[ENRL_REC MEDIUM_AFFINITY ACAD_EXCEPTION_WRK:0.22]
```

The `IS_HUB degree:5.0` annotation signals that `ENRL_REC` is the central node of the RegistrarCore community — it joins to at least 5 other tables. The `MEDIUM_AFFINITY ACAD_EXCEPTION_WRK:0.22` confirms co-occurrence in the workload: these two tables appear together frequently enough that the affinity score exceeds the MEDIUM threshold. This is the mathematical evidence, extracted from real SQL patterns, that told the LLM a join between these tables is not only possible but common in practice.

#### `STU_MST` — The Hub That Bridges Four Communities

```
[STU_MST BRIDGES Bursar:Curriculum:FinancialAid:RegistrarCore]
[STU_MST JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK]
[STU_MST JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION]
[STU_MST JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK→BURS_STUDENT_ACCOUNT]
[STU_MST IN_COMMUNITY RegistrarCore]
[STU_MST IS_HUB degree:9.0]
[STU_MST JOINS_WITH ENRL_REC]
[STU_MST MEDIUM_AFFINITY ENRL_REC:0.38]
```

`STU_MST` is the highest-degree hub in the schema at `IS_HUB degree:9.0` — it connects to 9 other tables across 4 communities. The `JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK` annotation on the student master table confirms the chain from the other direction. Both the origin table (`STU_MST`) and the target table (`ACAD_EXCEPTION_WRK`) carry this annotation — the LLM sees consistent evidence from two independent starting points that `ENRL_REC` is the required bridge.

---

## Scenario 2 — Opaque Work Table Bridge (Pending Medical Withdrawal Approvals)

**Demonstrates:** The same contractor-built exception tracking table (`ACAD_EXCEPTION_WRK`) requires the same `ENRL_REC` bridge for medical withdrawal queries as it does for grade change queries. Column comments now document valid `AEW_TYPE_CD` values — so the baseline correctly uses `WTHDR_MED` rather than guessing a LIKE pattern. The join path failure, however, is unchanged: the baseline still has no evidence that `ENRL_REC` bridges exceptions to students, invents the same `ENRL_KEY` column name, and fails with the same ORA-00904 error.

### The Question

> "Which students have a pending medical withdrawal exception that has not yet been approved"

This is a **medical withdrawal review query** — the kind a dean of students office runs when a student petitions to withdraw from all courses for medical reasons after the withdrawal deadline. Medical withdrawals require dual approval (departmental and dean-level) before they take effect. The approvals gate tuition refunds, academic record amendments, and financial aid adjustments. A dean of students processing the approval queue needs a list of pending cases, with student contact info and enrollment term, to work the queue before the semester's administrative deadline.

The correct answer requires the same three-table chain as Scenario 1: `STU_MST → ENRL_REC → ACAD_EXCEPTION_WRK`. The join condition is identical (`AEW_ENRL_KEY = ENRL_REC.ER_ID`). The type filter changes to `WTHDR_MED`; the status filter remains `PEND`. Neither the type code nor the join column is documented via FK constraints. The type code is now documented in a column comment; the join column is not.

### Command

```bash
python -m src.pipeline.query_pipeline \
  "Which students have a pending medical withdrawal exception that has not yet been approved" \
  --schema university --compare --ddl-baseline --count-total --debug-annotations
```

---

### Standard RAG (baseline) — Same Bridge Failure, Correct Code Value

**Tables selected:** `ACAD_EXCEPTION_WRK, STU_MST`

Note: `ENRL_REC` was not selected. The baseline had no evidence it was required — same as Scenario 1. However, the column comment on `AEW_TYPE_CD` is visible in the DDL, so the baseline correctly used `WTHDR_MED` rather than guessing `LIKE '%MED%'`. The join path failure is unchanged.

```sql
SELECT s.STU_FNM, s.STU_LNM, s.STU_EMAIL, s.STU_LVL,
       a.AEW_ID, a.AEW_SUBM_DT, a.AEW_DEPT_APRV, a.AEW_DEAN_APRV, a.AEW_NOTES
FROM UNIV_SCHEMARAG.ACAD_EXCEPTION_WRK a
JOIN UNIV_SCHEMARAG.ENRL_REC e ON e.ENRL_KEY = a.AEW_ENRL_KEY   -- ← invented column name
JOIN UNIV_SCHEMARAG.STU_MST s ON s.STU_ID = e.STU_ID
WHERE a.AEW_TYPE_CD = 'WTHDR_MED'
  AND UPPER(a.AEW_STAT_CD) LIKE '%PEND%'
  AND (NVL(a.AEW_DEPT_APRV, 'N') != 'Y' OR NVL(a.AEW_DEAN_APRV, 'N') != 'Y')
FETCH FIRST 100 ROWS ONLY
```

**Result:** SQL Error — `ORA-00904: "E"."ENRL_KEY": invalid identifier`

The column `ENRL_KEY` does not exist. The primary key of `ENRL_REC` is `ER_ID`. The baseline knew `ENRL_REC` was the intermediary (it attempted to join through it despite not selecting it), but had no DDL for the table and constructed `ENRL_KEY` as a plausible English surrogate. The code value `WTHDR_MED` is correct — the column comment is visible. But the query cannot execute.

---

### SchemaRAG (annotated) — Correct Bridge, 160 Rows

**Tables selected:** `ACAD_EXCEPTION_WRK, ENRL_REC, STU_MST`

Note: `ENRL_REC` was added by SchemaRAG. The `JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK` annotation on `ACAD_EXCEPTION_WRK` named it explicitly, and the annotated retriever selected it. With the DDL for `ENRL_REC` in context, the correct column names were available.

```sql
SELECT
    s.STU_FNM,
    s.STU_LNM,
    s.STU_EMAIL,
    s.STU_LVL,
    a.AEW_ID,
    a.AEW_STAT_CD,
    a.AEW_SUBM_DT,
    a.AEW_DEPT_APRV,
    a.AEW_DEAN_APRV,
    a.AEW_NOTES,
    e.ER_TERM_CD,
    e.ER_SECT_ID
FROM UNIV_SCHEMARAG.ACAD_EXCEPTION_WRK a
JOIN UNIV_SCHEMARAG.ENRL_REC e
    ON e.ER_ID = a.AEW_ENRL_KEY          -- ← correct: ER_ID is the PK, not ENRL_KEY
JOIN UNIV_SCHEMARAG.STU_MST s
    ON s.STU_ID = e.ER_STU_ID            -- ← correct: ER_STU_ID links enrollment to student
WHERE a.AEW_TYPE_CD = 'WTHDR_MED'
    AND UPPER(a.AEW_STAT_CD) LIKE '%PEND%'
    AND (NVL(a.AEW_DEPT_APRV, 'N') <> 'Y' OR NVL(a.AEW_DEAN_APRV, 'N') <> 'Y')
FETCH FIRST 100 ROWS ONLY
```

**Result:** 100 rows (total without limit: 160). One row per pending medical withdrawal with at least one outstanding approval, showing student name, email, enrollment term, section, submission date, and current approval status from both the department and dean levels.

---

### Why SchemaRAG Wins

**This scenario isolates the join path problem from the code value problem.** In Scenario 1, the baseline could have failed either because it guessed the wrong code value OR because it missed the bridge table — two independent failure modes. In Scenario 2, only one failure mode remains: the baseline correctly identifies `WTHDR_MED` (the column comment is now visible in the DDL) but still cannot construct the join. The ORA-00904 error is not about code values. It is purely about the missing join path.

**The column comment made the code value problem go away.** `COMMENT ON COLUMN acad_exception_wrk.aew_type_cd IS 'Exception type code: GRD_CHNG=Grade change, WTHDR_MED=Medical withdrawal, ...'` is part of the DDL that every retrieval path sees. The baseline used `WTHDR_MED` exactly — no LIKE guessing. This is the expected behavior when code values are documented. The demo now separates two distinct failure modes: code value guessing (solved by column comments) and join path discovery (solved by workload annotations).

**The join path failure is structural and deterministic.** `ACAD_EXCEPTION_WRK.AEW_ENRL_KEY` has no column comment, no FK constraint, no index, and no name similarity to `ENRL_REC.ER_ID`. A DDL scan has no path from the exception table to the student master. The baseline attempted to use `ENRL_REC` anyway and invented a plausible column name — `ENRL_KEY` — that does not exist. The same guessing behavior that failed in Scenario 1 fails identically here, regardless of question framing. The failure is not sensitive to question wording; it is sensitive to whether the workload evidence is available.

**160 pending approvals are invisible.** A dean of students processing the medical withdrawal queue cannot see these cases. Medical withdrawals have financial consequences — tuition refund windows close, financial aid adjustments trigger, and academic record amendments require formal resolution. If the query cannot execute, the approval queue is unavailable and cases age past the administrative deadline without action.

---

### Join Path Illustrations

#### Standard RAG (baseline) — Correct Code Value, Invented Column

The column comment for `AEW_TYPE_CD` is now visible in the DDL. The baseline uses `WTHDR_MED` correctly. But `ENRL_REC` is still not retrieved, and the join column is still invented.

```
STU_MST
    │
    │  (no direct path to exceptions)
    │
    ▼
ACAD_EXCEPTION_WRK
    │
    │  e.ENRL_KEY = a.AEW_ENRL_KEY  ← ENRL_KEY does not exist
    ▼
ENRL_REC  (not retrieved — no DDL available)
           ORA-00904: "E"."ENRL_KEY": invalid identifier


AEW_TYPE_CD = 'WTHDR_MED'  ← CORRECT (column comment documented the value)
AEW_STAT_CD LIKE '%PEND%'  ← CORRECT
ENRL_REC                   ← NOT RETRIEVED
```

**Result:** SQL error. Query cannot execute.

---

#### SchemaRAG (annotated) — Three-Hop Chain, 160 Rows

Same `JOINS_PATH` annotation as Scenario 1. Same bridge table. Same columns. Different business question, identical solution path.

```
STU_MST
    │
    │  s.STU_ID = e.ER_STU_ID
    ▼
ENRL_REC  ◄── BRIDGE TABLE (retrieved via JOINS_PATH annotation)
    │  [ACAD_EXCEPTION_WRK JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK]
    │  [ENRL_REC MEDIUM_AFFINITY ACAD_EXCEPTION_WRK:0.22]
    │  [ENRL_REC IS_HUB degree:5.0]
    │
    │  e.ER_ID = a.AEW_ENRL_KEY    ← correct: ER_ID is the primary key
    ▼
ACAD_EXCEPTION_WRK
(AEW_TYPE_CD = 'WTHDR_MED'
 AEW_STAT_CD = 'PEND'
 dept or dean approval outstanding)
```

**Result:** 160 rows. Students with pending medical withdrawals awaiting departmental or dean approval, with enrollment term, section, and dual-approval status.

---

### What This Scenario Adds to the Demo

Scenario 2 is not simply a repeat of Scenario 1. It makes two distinct contributions:

**1. Confirms the bridge failure is query-independent.** The same `ENRL_REC` bridge fails to appear in the baseline for a completely different question. This rules out the possibility that Scenario 1 was a one-time coincidence of question wording. The failure is a property of the schema, not of a particular query.

**2. Cleanly isolates the join path problem.** With code values now documented via column comments, the baseline's only remaining failure is the join path. The demo audience sees a baseline that did everything right — selected the correct tables conceptually, used the correct code value — and still cannot execute because the physical join column is undiscoverable from DDL alone. That is the problem SchemaRAG solves.

---

## Scenario 3 — Cross-Community Join Path (Approved Exception, Active Bursar Hold)

**Demonstrates:** A query that must cross two schema communities — RegistrarCore (academic exceptions) and Bursar (financial holds) — through a 5-hop join chain. The baseline fails twice in the same query: once on the RegistrarCore side (inventing a column name on `ENRL_REC`) and once on the Bursar side (missing `BURS_STUDENT_ACCOUNT` as the required intermediate between the student master and the hold table). The annotated side retrieves all six required tables and the correct join chain via `BRIDGES` and `JOINS_PATH` annotations that cross community boundaries.

### The Question

> "Which students have an approved academic exception but still have an active bursar hold on their account?"

This is a **registration clearance reconciliation query** — the kind a registrar's office runs when exceptions have been resolved on the academic side but students are still being blocked from re-enrolling by a financial hold. A student whose medical withdrawal was approved may still have an outstanding balance from the withdrawn term. Their exception is closed; their bursar hold is not. Until both are resolved, the student cannot register for the next term. The registrar needs a reconciliation list to route these students to the bursar's office and close the gap.

The correct join chain spans two communities: `ACAD_EXCEPTION_WRK → ENRL_REC → STU_MST → BURS_STUDENT_ACCOUNT → BURS_STUDENT_HOLD`. The `BURS_STUDENT_ACCOUNT` table is the required intermediate between the student master (RegistrarCore) and the hold table (Bursar) — it is the account record that holds are placed against. There is no direct join from `STU_MST` to `BURS_STUDENT_HOLD`. This intermediate is not documented anywhere in the DDL: no FK constraint, no column comment, no table comment referencing the relationship. The path exists only in the workload — the application has always navigated it this way.

### Command

```bash
python -m src.pipeline.query_pipeline \
  "Which students have an approved academic exception but still have an active bursar hold on their account" \
  --schema university --compare --ddl-baseline --count-total --debug-annotations
```

---

### Standard RAG (baseline) — Two Independent Failures, One Query

**Tables selected:** `ACAD_EXCEPTION_WRK, BURS_HOLD_CODE, BURS_STUDENT_HOLD, STU_MST`

Note: `ENRL_REC` and `BURS_STUDENT_ACCOUNT` were not selected. The baseline had no evidence either was required. The column comment on `AEW_STAT_CD` is now visible in the DDL — the baseline correctly used `'APRV'` rather than guessing `LIKE '%APPR%'`. Both join chains failed independently.

```sql
SELECT DISTINCT
    sm.STU_ID, sm.STU_FNM, sm.STU_LNM, sm.STU_EMAIL, sm.STU_STAT_CD,
    aew.AEW_TYPE_CD, aew.AEW_DCSN_DT,
    bsh.HOLD_CODE, bhc.HOLD_DESC, bsh.HOLD_AMT, bsh.PLACED_DT
FROM UNIV_SCHEMARAG.STU_MST sm
JOIN UNIV_SCHEMARAG.ENRL_REC er ON er.STU_ID = sm.STU_ID       -- ← invented: ER has ER_STU_ID not STU_ID
JOIN UNIV_SCHEMARAG.ACAD_EXCEPTION_WRK aew ON aew.AEW_ENRL_KEY = er.ENRL_ID  -- ← invented: ENRL_ID does not exist
JOIN UNIV_SCHEMARAG.BURS_STUDENT_HOLD bsh ON bsh.BSA_ID = sm.STU_ID  -- ← wrong: BSA_ID → BURS_STUDENT_ACCOUNT.BSA_ID
JOIN UNIV_SCHEMARAG.BURS_HOLD_CODE bhc ON bhc.HOLD_CODE = bsh.HOLD_CODE
WHERE aew.AEW_STAT_CD = 'APRV'                                  -- ← correct: column comment worked
  AND bsh.RELEASED_DT IS NULL
  AND bhc.ACTIVE = 'Y'
ORDER BY sm.STU_LNM, sm.STU_FNM
FETCH FIRST 100 ROWS ONLY
```

**Result:** SQL Error — `ORA-00904: "ER"."STU_ID": invalid identifier`

`ENRL_REC` has no column named `STU_ID`. The actual column is `ER_STU_ID`. The baseline also invented `er.ENRL_ID` as the join column for the exception key — a third invented name across three scenario runs (`ENRL_KEY` in Scenario 1, `ENRL_KEY` in Scenario 2, `ENRL_ID` here). The guesses are plausible English constructions but each is wrong, and they are not consistent — the baseline does not even guess the same wrong name reliably. Additionally, `bsh.BSA_ID = sm.STU_ID` attempts to join `BURS_STUDENT_HOLD` directly to the student master, treating `BSA_ID` as a student ID. It is a foreign key to `BURS_STUDENT_ACCOUNT.BSA_ID`. The intermediate account table is entirely absent.

---

### SchemaRAG (annotated) — 5-Hop Cross-Community Chain, 57 Rows

**Tables selected:** `ACAD_EXCEPTION_WRK, BURS_HOLD_CODE, BURS_STUDENT_ACCOUNT, BURS_STUDENT_HOLD, ENRL_REC, STU_MST`

Note: `ENRL_REC` and `BURS_STUDENT_ACCOUNT` were both added by SchemaRAG. The annotation `[ACAD_EXCEPTION_WRK JOINS_PATH ACAD_EXCEPTION_WRK→ENRL_REC→STU_MST→BURS_STUDENT_ACCOUNT→BURS_STUDENT_HOLD]` provided the complete 5-hop chain, including `BURS_STUDENT_ACCOUNT` as the required cross-community bridge. The `[ACAD_EXCEPTION_WRK BRIDGES Bursar:RegistrarCore]` annotation confirmed the table spans both communities, guiding retrieval toward the Bursar tables.

```sql
SELECT DISTINCT
    s.STU_FNM, s.STU_LNM, s.STU_EMAIL, s.STU_LVL,
    aew.AEW_TYPE_CD, aew.AEW_DCSN_DT,
    bh.HOLD_CODE, bhc.HOLD_DESC, bh.PLACED_DT, bh.HOLD_AMT,
    bsa.CURRENT_BALANCE, bsa.ACCT_STATUS
FROM UNIV_SCHEMARAG.ACAD_EXCEPTION_WRK aew
JOIN UNIV_SCHEMARAG.ENRL_REC er
    ON er.ER_ID = aew.AEW_ENRL_KEY          -- ← correct: ER_ID is the PK
JOIN UNIV_SCHEMARAG.STU_MST s
    ON s.STU_ID = er.ER_STU_ID              -- ← correct: ER_STU_ID links enrollment to student
JOIN UNIV_SCHEMARAG.BURS_STUDENT_ACCOUNT bsa
    ON bsa.STUDENT_NBR = s.STU_ID           -- ← correct: BURS_STUDENT_ACCOUNT as required intermediate
JOIN UNIV_SCHEMARAG.BURS_STUDENT_HOLD bh
    ON bh.BSA_ID = bsa.BSA_ID              -- ← correct: BSA_ID links hold to account, not student
JOIN UNIV_SCHEMARAG.BURS_HOLD_CODE bhc
    ON bhc.HOLD_CODE = bh.HOLD_CODE
WHERE aew.AEW_STAT_CD = 'APRV'             -- ← correct: column comment documented APRV=Approved
  AND bh.RELEASED_DT IS NULL
  AND bhc.ACTIVE = 'Y'
FETCH FIRST 100 ROWS ONLY
```

**Result:** 57 rows (total without limit: 57). Students with fully approved academic exceptions who still have an unreleased, active bursar hold — showing hold type, hold amount, account balance, and decision date of the approved exception.

---

### Why SchemaRAG Wins

**The baseline fails twice, independently.** Most NL2SQL failure scenarios involve a single missing table or a single wrong column. This scenario reveals two separate structural gaps in DDL-only retrieval, operating on opposite sides of the query:

**Failure 1 — RegistrarCore join chain (same as Scenarios 1 and 2).** The baseline cannot join `ACAD_EXCEPTION_WRK` to `STU_MST` without `ENRL_REC`, and it cannot name `ENRL_REC`'s columns correctly even when it guesses the table is needed. Across three scenario runs, the baseline invented three different names for the same join column: `ENRL_KEY`, `ENRL_KEY`, and `ENRL_ID`. The guesses are plausible English constructions — a table named "enrollment record" plausibly has a key column called any of those — but all are wrong, and the guesses are not even consistent across runs. The failure is non-deterministic in its specific wrong answer but deterministic in its outcome: ORA-00904 every time.

**Failure 2 — Bursar join chain (new in this scenario).** The baseline attempted `bsh.BSA_ID = sm.STU_ID` — joining `BURS_STUDENT_HOLD` directly to `STU_MST` by treating `BSA_ID` as a student identifier. `BSA_ID` is the primary key of `BURS_STUDENT_ACCOUNT`. The actual join from student to hold always passes through the account record. There is no FK, no column comment, and no table comment that documents this. The application has always joined `STU_MST → BURS_STUDENT_ACCOUNT → BURS_STUDENT_HOLD`. That workload pattern is the only evidence the intermediate exists, and it was captured in the STS.

**The column comment fix worked.** The `APRV=Approved` comment on `AEW_STAT_CD` is now in `ALL_COL_COMMENTS`. Both sides used `AEW_STAT_CD = 'APRV'` exactly — the first scenario where the baseline used the correct code value AND failed on join paths. This cleanly separates the two problem categories: code value guessing (solved by column comments visible to all retrieval paths) and join path discovery (solved only by workload annotations).

**57 students in limbo.** Their exceptions were approved — the academic side said yes. The bursar's hold was never lifted. Without this query, there is no automatic reconciliation view. Registration opens, these students cannot enroll, and neither the registrar nor the bursar has a cross-system list to work from. SchemaRAG surfaces the list; the baseline cannot.

---

### Join Path Illustrations

#### Standard RAG (baseline) — Two Failures Across Two Communities

```
STU_MST
    │
    │  er.STU_ID = sm.STU_ID  ← STU_ID does not exist on ENRL_REC
    ▼
ENRL_REC  (not retrieved — DDL unavailable)
    │
    │  aew.AEW_ENRL_KEY = er.ENRL_ID  ← ENRL_ID does not exist (3rd different guess)
    ▼
ACAD_EXCEPTION_WRK
    AEW_STAT_CD = 'APRV'  ← CORRECT (column comment worked)

STU_MST
    │
    │  bsh.BSA_ID = sm.STU_ID  ← wrong: BSA_ID references BURS_STUDENT_ACCOUNT.BSA_ID
    ▼
BURS_STUDENT_HOLD  ← joined incorrectly; BURS_STUDENT_ACCOUNT not retrieved
    │
    ▼
BURS_HOLD_CODE

ORA-00904: "ER"."STU_ID": invalid identifier
```

**Result:** SQL error. Two independent failures; neither join chain is traversable.

---

#### SchemaRAG (annotated) — 5-Hop Cross-Community Chain

The `JOINS_PATH` annotation on `ACAD_EXCEPTION_WRK` provides the full 5-hop sequence including `BURS_STUDENT_ACCOUNT`. The `BRIDGES Bursar:RegistrarCore` annotation confirms the cross-community scope.

```
ACAD_EXCEPTION_WRK  [BRIDGES Bursar:RegistrarCore]
    │               [JOINS_PATH ACAD_EXCEPTION_WRK→ENRL_REC→STU_MST→BURS_STUDENT_ACCOUNT→BURS_STUDENT_HOLD]
    │  er.ER_ID = aew.AEW_ENRL_KEY
    ▼
ENRL_REC  ◄── BRIDGE 1 (RegistrarCore)
    │  s.STU_ID = er.ER_STU_ID
    ▼
STU_MST  [IS_HUB degree:9.0] [BRIDGES Bursar:Curriculum:FinancialAid:RegistrarCore]
    │  bsa.STUDENT_NBR = s.STU_ID
    ▼
BURS_STUDENT_ACCOUNT  ◄── BRIDGE 2 (cross-community: RegistrarCore → Bursar)
    │  [IS_HUB degree:5.0] [BRIDGES Bursar:RegistrarCore]
    │  bh.BSA_ID = bsa.BSA_ID
    ▼
BURS_STUDENT_HOLD
    │  bhc.HOLD_CODE = bh.HOLD_CODE
    ▼
BURS_HOLD_CODE
    (RELEASED_DT IS NULL AND ACTIVE = 'Y')

AEW_STAT_CD = 'APRV'  ← exact code from column comment
```

**Result:** 57 rows. Students with approved exceptions who remain blocked by active unreleased bursar holds, with hold type, amount, account balance, and exception decision date.

---

### Annotations That Drove the Result

The critical annotation on `ACAD_EXCEPTION_WRK`:

```
[ACAD_EXCEPTION_WRK JOINS_PATH ACAD_EXCEPTION_WRK→ENRL_REC→STU_MST→BURS_STUDENT_ACCOUNT→BURS_STUDENT_HOLD]
[ACAD_EXCEPTION_WRK BRIDGES Bursar:RegistrarCore]
[ACAD_EXCEPTION_WRK MEDIUM_AFFINITY ENRL_REC:0.22]
[ACAD_EXCEPTION_WRK LOW_AFFINITY BURS_STUDENT_ACCOUNT:0.10]
```

The `JOINS_PATH` provides the full 5-hop sequence. The `BRIDGES` annotation confirms `ACAD_EXCEPTION_WRK` spans both communities, which caused the retriever to look for Bursar tables as well as RegistrarCore tables. The affinity scores confirm both relationships appear in real workload queries — not hypothetical paths, but proven patterns from the STS.

On `STU_MST`:

```
[STU_MST JOINS_PATH ACAD_EXCEPTION_WRK→ENRL_REC→STU_MST→BURS_STUDENT_ACCOUNT→BURS_STUDENT_HOLD]
[STU_MST BRIDGES Bursar:Curriculum:FinancialAid:RegistrarCore]
[STU_MST IS_HUB degree:9.0]
[STU_MST MEDIUM_AFFINITY ENRL_REC:0.38]
```

`STU_MST` carries the same 5-hop path annotation from the other direction, and its `BRIDGES` annotation spans all four major communities. The retriever saw consistent evidence from multiple tables that `BURS_STUDENT_ACCOUNT` belongs in the join chain — not from any one annotation alone, but from a convergent signal across the retrieved set.

---

## Scenario 4 — Cryptic Names and Concept Mismatch (Honors Students with Unmet Financial Need)

**Demonstrates:** Two failure modes from the ERP scenario taxonomy — cryptic table names (#2) and concept mismatch (#10) — occurring simultaneously in a single query. The baseline retriever selects the wrong tables entirely, not because the join paths are missing but because the natural language terms in the question have no vocabulary overlap with the correct table names. The correct tables are named for their implementation (`NEED_ANALYSIS_RESULT`, `STU_FA_XREF`) rather than the business concept the user expressed ("financial need," "honors program"). Without graph community context, semantic similarity retrieval anchors to plausible-sounding wrong tables and the query never gets off the ground.

### The Question

> "Show me students in the honors program whose financial aid need analysis shows unmet need"

This is a **financial aid prioritization query** — the kind a financial aid director runs to identify high-achieving students who qualify for additional scholarship consideration. Honors students with unmet financial need are often the first candidates for discretionary awards, emergency funds, and donor-directed scholarships. The financial aid office needs this list before packaging decisions close for the aid year.

The correct join chain is `STU_MST → STU_FA_XREF → FINANCIAL_AID_APPLICATION → NEED_ANALYSIS_RESULT`. None of these table names contain the words "honors," "financial need," or "unmet." `STU_HONORS` is a column on `STU_MST`, not a table. `NEED_ANALYSIS_RESULT` is the system's name for the federal need analysis calculation — the business calls it "financial need" or "EFC analysis." `STU_FA_XREF` is a cross-reference table whose name gives no indication that it is the required bridge between the student master and the financial aid application system. The 4-hop chain is invisible to a retriever operating on name similarity alone.

### Command

```bash
python -m src.pipeline.query_pipeline \
  "Show me students in the honors program whose financial aid need analysis shows unmet need" \
  --schema university --compare --ddl-baseline --count-total --debug-annotations
```

---

### Standard RAG (baseline) — Wrong Tables, Wrong Columns

**Tables selected:** `ACAD_STAT_TBL, FA_AWARD_HISTORY, NEED_ANALYSIS_RESULT, STU_MST`

Note: The baseline selected `ACAD_STAT_TBL` and `FA_AWARD_HISTORY` instead of `STU_FA_XREF` and `FINANCIAL_AID_APPLICATION`. "Honors" semantically resembles "academic standing" → `ACAD_STAT_TBL`. "Financial need" partially resembles "award history" → `FA_AWARD_HISTORY`. Both are plausible vocabulary matches. Both are wrong. `STU_FA_XREF` — the required cross-reference bridge — has no name that signals its role. `FINANCIAL_AID_APPLICATION` — the required intermediate — was not retrieved.

Despite not selecting `STU_FA_XREF`, the baseline attempted to use it in the generated SQL, joining via `x.STU_ID` — a column that does not exist on that table. The actual column is `SFX_STU_ID`.

```sql
SELECT
    s.STU_ID, s.STU_FNM, s.STU_LNM, s.STU_LVL, s.STU_GPA,
    n.NAR_RUN_DATE, n.EFC_FEDERAL, n.EFC_INSTITUTIONAL,
    n.COA_ON_CAMPUS, n.COA_OFF_CAMPUS,
    n.UNMET_NEED_FEDERAL, n.UNMET_NEED_INST, n.PELL_ELIGIBLE
FROM UNIV_SCHEMARAG.STU_MST s
JOIN UNIV_SCHEMARAG.STU_FA_XREF x
    ON s.STU_ID = x.STU_ID                -- ← STU_FA_XREF not retrieved; STU_ID does not exist (SFX_STU_ID)
JOIN UNIV_SCHEMARAG.NEED_ANALYSIS_RESULT n
    ON x.FAA_ID = n.FAA_ID               -- ← FAA_ID does not exist on STU_FA_XREF; FINANCIAL_AID_APPLICATION missing
WHERE s.STU_HONORS = 'Y'
  AND s.STU_STAT_CD = 'A'
  AND (NVL(n.UNMET_NEED_FEDERAL, 0) > 0 OR NVL(n.UNMET_NEED_INST, 0) > 0)
ORDER BY GREATEST(NVL(n.UNMET_NEED_FEDERAL, 0), NVL(n.UNMET_NEED_INST, 0)) DESC
FETCH FIRST 100 ROWS ONLY
```

**Result:** SQL Error — `ORA-00904: "X"."STU_ID": invalid identifier`

The baseline failed at the retrieval step before it ever reached the join path. It started with the wrong tables, then compounded the error with invented column names on a table it did not even retrieve. The failure here is earlier and more fundamental than in Scenarios 1–3.

---

### SchemaRAG (annotated) — Correct 4-Hop Chain, 25 Rows

**Tables selected:** `ACAD_STAT_TBL, FINANCIAL_AID_APPLICATION, NEED_ANALYSIS_RESULT, STU_FA_XREF, STU_MST`

Note: The annotated retriever correctly selected `STU_FA_XREF` and `FINANCIAL_AID_APPLICATION` because `STU_MST`'s annotation includes `[STU_MST JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→NEED_ANALYSIS_RESULT]` — naming all three downstream tables explicitly. `ACAD_STAT_TBL` was also retrieved (a minor extra) but was not used in the generated SQL.

```sql
SELECT
    sm.STU_FNM, sm.STU_LNM, sm.STU_LVL, sm.STU_GPA,
    faa.AID_YEAR, faa.EFC_AMOUNT, faa.STATUS AS FA_STATUS,
    nar.EFC_FEDERAL, nar.EFC_INSTITUTIONAL,
    nar.COA_ON_CAMPUS, nar.COA_OFF_CAMPUS,
    nar.UNMET_NEED_FEDERAL, nar.UNMET_NEED_INST,
    nar.PELL_ELIGIBLE, nar.NAR_RUN_DATE
FROM UNIV_SCHEMARAG.STU_MST sm
JOIN UNIV_SCHEMARAG.STU_FA_XREF sfx
    ON sfx.SFX_STU_ID = sm.STU_ID             -- ← correct: SFX_STU_ID is the actual column
JOIN UNIV_SCHEMARAG.FINANCIAL_AID_APPLICATION faa
    ON faa.FA_STU_KEY = sm.STU_ID             -- ← correct: FA_STU_KEY links application to student
JOIN UNIV_SCHEMARAG.NEED_ANALYSIS_RESULT nar
    ON nar.FAA_ID = faa.FAA_ID                -- ← correct: FAA_ID links need analysis to application
WHERE sm.STU_HONORS = 'Y'
  AND (NVL(nar.UNMET_NEED_FEDERAL, 0) > 0 OR NVL(nar.UNMET_NEED_INST, 0) > 0)
ORDER BY nar.UNMET_NEED_FEDERAL DESC NULLS LAST, nar.UNMET_NEED_INST DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY
```

**Result:** 25 rows (total without limit: 25). Honors students with unmet federal or institutional need, showing EFC amounts, cost of attendance figures, Pell eligibility, and financial aid application status — exactly the information a financial aid director needs to identify scholarship candidates.

---

### Why SchemaRAG Wins

**This scenario fails at the retrieval step, not the join step.** In Scenarios 1–3, the baseline selected conceptually correct tables and failed because it could not name the join columns or identify the bridge table. Here the baseline never selected the right tables in the first place. "Financial need analysis" and "honors program" are business concepts with no direct vocabulary match to `NEED_ANALYSIS_RESULT`, `STU_FA_XREF`, or `FINANCIAL_AID_APPLICATION`. The retriever matched surface semantics and arrived at the wrong destination before generating a single line of SQL.

**Two failure modes compound each other.** This query hits both Scenario #2 (cryptic names) and Scenario #10 (concept mismatch) from the ERP scenario taxonomy simultaneously:

- **Cryptic names:** `NEED_ANALYSIS_RESULT` is the system's internal name for what financial aid staff call "need analysis" or "EFC calculation." `STU_FA_XREF` is a cross-reference table whose name gives no indication of its role as the bridge to financial aid. `SFX_STU_ID` and `FAA_ID` are opaque prefixed column names with no natural language analog.
- **Concept mismatch:** "Honors program" is a student attribute (`STU_HONORS = 'Y'` on `STU_MST`), not a table. "Financial need" is stored across four tables connected by a chain that has nothing in common with the phrase. The business vocabulary and the schema vocabulary are entirely disjoint.

**The annotated retriever succeeded because the path annotation bridged the vocabulary gap.** `[STU_MST JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→NEED_ANALYSIS_RESULT]` is not a vocabulary match — it is structural evidence. The annotation tells the retriever that when a question involves `STU_MST`, these three downstream tables have been used together repeatedly in production queries. The retriever does not need to understand that `NEED_ANALYSIS_RESULT` means "financial need"; it only needs to see that the workload has repeatedly joined these tables together and that `NEED_ANALYSIS_RESULT` is at the end of a proven chain from the student master.

**25 honors students with unmet need are invisible to the baseline.** These are the students a financial aid director would prioritize for discretionary awards, emergency fund access, and donor scholarship matching. Without the correct table chain, the query cannot execute and the list does not exist.

---

### Join Path Illustrations

#### Standard RAG (baseline) — Wrong Tables, Retrieval Failure Before Join Failure

```
Question vocabulary:           Schema vocabulary:
"honors program"        →      ACAD_STAT_TBL  ← wrong (academic standing, not honors flag)
"financial need"        →      FA_AWARD_HISTORY ← wrong (award history, not need analysis)
"need analysis"         →      NEED_ANALYSIS_RESULT ← correct, but unreachable without bridge

STU_MST
    │
    │  x.STU_ID = s.STU_ID  ← STU_ID does not exist on STU_FA_XREF (not retrieved)
    ▼
STU_FA_XREF  (not retrieved — no DDL available)
    │
    │  x.FAA_ID = n.FAA_ID  ← FAA_ID does not exist on STU_FA_XREF
    ▼                          FINANCIAL_AID_APPLICATION not retrieved
NEED_ANALYSIS_RESULT

ORA-00904: "X"."STU_ID": invalid identifier
```

**Result:** SQL error. Wrong tables retrieved, then wrong columns on an unretrieved table.

---

#### SchemaRAG (annotated) — 4-Hop Chain via JOINS_PATH Annotation

```
STU_MST  [IS_HUB degree:9.0] [BRIDGES Bursar:Curriculum:FinancialAid:RegistrarCore]
    │     [JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→NEED_ANALYSIS_RESULT]
    │
    │  sfx.SFX_STU_ID = sm.STU_ID
    ▼
STU_FA_XREF  ◄── BRIDGE (retrieved via JOINS_PATH annotation)
    │  [STU_FA_XREF BRIDGES FinancialAid:RegistrarCore]
    │
    │  faa.FA_STU_KEY = sm.STU_ID
    ▼
FINANCIAL_AID_APPLICATION  ◄── INTERMEDIATE (retrieved via JOINS_PATH annotation)
    │  [FINANCIAL_AID_APPLICATION IS_HUB degree:4.0]
    │
    │  nar.FAA_ID = faa.FAA_ID
    ▼
NEED_ANALYSIS_RESULT
(UNMET_NEED_FEDERAL > 0 OR UNMET_NEED_INST > 0)

STU_HONORS = 'Y'  ← column on STU_MST, not a table
```

**Result:** 25 rows. Honors students with unmet federal or institutional need, with full EFC breakdown and aid application status.

---

### Annotations That Drove the Result

On `STU_MST`:

```
[STU_MST JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→NEED_ANALYSIS_RESULT]
[STU_MST JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→PELL_ELIGIBILITY_TBL]
[STU_MST JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→FA_AWARD_HISTORY]
[STU_MST BRIDGES Bursar:Curriculum:FinancialAid:RegistrarCore]
[STU_MST IS_HUB degree:9.0]
[STU_MST LOW_AFFINITY STU_FA_XREF:0.19]
```

The `JOINS_PATH` annotation names all three downstream tables in sequence. The `BRIDGES` annotation confirms `STU_MST` spans the FinancialAid community, directing the retriever toward financial aid tables rather than academic standing tables. The affinity score `LOW_AFFINITY STU_FA_XREF:0.19` confirms the relationship appears in the workload — not frequently, but enough to be captured. Low affinity is still workload-proven; it is not a hypothetical path.

On `NEED_ANALYSIS_RESULT`:

```
[NEED_ANALYSIS_RESULT JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→NEED_ANALYSIS_RESULT]
[NEED_ANALYSIS_RESULT BRIDGES FinancialAid:RegistrarCore]
[NEED_ANALYSIS_RESULT IS_HUB degree:4.0]
[NEED_ANALYSIS_RESULT MEDIUM_AFFINITY STU_FA_XREF:0.23]
[NEED_ANALYSIS_RESULT MEDIUM_AFFINITY FINANCIAL_AID_APPLICATION:0.20]
```

`NEED_ANALYSIS_RESULT` carries the same path annotation from the other direction. The `BRIDGES FinancialAid:RegistrarCore` annotation confirms it spans communities. Both the origin (`STU_MST`) and the destination (`NEED_ANALYSIS_RESULT`) independently point to the same 4-hop chain — the retriever saw convergent evidence from two ends of the path simultaneously.

---

## Scenario 5 — Cross-Community Bridge Table (Merit Aid Students on SAP Probation)

**Demonstrates:** A query spanning the RegistrarCore and FinancialAid communities through `STU_FA_XREF`, an undeclared bridge table with opaque prefixed column names and no FK constraints. The baseline selects conceptually plausible tables and constructs an invalid join column (`STU_ID` does not exist on `STU_FA_XREF`), producing a SQL error. The annotated side retrieves the correct 5-table chain — including `STU_FA_XREF` and `FINANCIAL_AID_APPLICATION` — via the `BRIDGES FinancialAid:RegistrarCore` annotation and the `STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→FA_AWARD_HISTORY` join path, returning 198 rows. This is Scenario 8 from the ERP taxonomy: a cross-module bridge table with no declared relationship and opaque naming.

### The Question

> "Which students receiving merit scholarships have a SAP probation standing on record?"

This is a **financial aid compliance query** — the kind a financial aid office runs before the Satisfactory Academic Progress (SAP) review deadline each term. Federal regulations require that students receiving aid maintain SAP. Merit scholarship recipients who fall to probationary standing are at risk of losing their awards in the next packaging cycle. The financial aid director needs a list of these students to initiate outreach, apply automatic holds, or flag them for manual review before award disbursement runs.

The correct join chain is `STU_MST → ACAD_STAT_TBL → STU_FA_XREF → FINANCIAL_AID_APPLICATION → FA_AWARD_HISTORY`. `STU_FA_XREF` is the undeclared cross-reference bridge between the student master (RegistrarCore) and the financial aid application system (FinancialAid). Its column names carry the `SFX_` prefix with no natural language analog — `SFX_STU_ID` and `SFX_FA_NBR`. `SFX_FA_NBR` is a VARCHAR2 display string formatted as `FA0000001` — not a numeric key, and not directly joinable to `FA_AWARD_HISTORY`. The correct join path traverses `FINANCIAL_AID_APPLICATION` as an intermediate, joining on `FA_STU_KEY = STU_MST.STU_ID` and `FAA_ID` linking to `FA_AWARD_HISTORY`. Without workload annotations, the bridge is invisible and the column semantics are unresolvable from DDL alone.

### Command

```bash
python -m src.pipeline.query_pipeline \
  "Which students receiving merit scholarships have a SAP probation standing on record" \
  --schema university --compare --ddl-baseline --count-total --debug-annotations
```

---

### Standard RAG (baseline) — Bridge Table Invisible, Invalid Column

**Tables selected:** `ACAD_STAT_TBL, FA_AWARD_HISTORY, SCHOLARSHIP_POOL, STU_MST`

Note: The baseline selected `SCHOLARSHIP_POOL` instead of `STU_FA_XREF` and omitted `FINANCIAL_AID_APPLICATION` entirely. "Merit scholarships" semantically resembles "scholarship pool" — a plausible vocabulary match. `STU_FA_XREF` has no name that signals its role as the student-to-financial-aid bridge. Despite not selecting `STU_FA_XREF`, the baseline attempted to use it in the generated SQL, joining via `xref.STU_ID = s.STU_ID` — a column that does not exist on that table. The actual column is `SFX_STU_ID`.

```sql
SELECT
    s.STU_ID, s.STU_FNM, s.STU_LNM, s.STU_LVL, s.STU_GPA,
    fah.AWARD_TYPE, fah.AWARD_AMOUNT, fah.AWARD_STATUS,
    ast.AS_STAT_CD, ast.AS_TERM_CD, ast.AS_GPA_ACT
FROM UNIV_SCHEMARAG.STU_MST s
JOIN UNIV_SCHEMARAG.STU_FA_XREF xref
    ON xref.STU_ID = s.STU_ID                  -- ← STU_ID does not exist on STU_FA_XREF (SFX_STU_ID)
JOIN UNIV_SCHEMARAG.FA_AWARD_HISTORY fah
    ON fah.FAA_ID = xref.FAA_ID                -- ← FAA_ID does not exist on STU_FA_XREF
JOIN UNIV_SCHEMARAG.ACAD_STAT_TBL ast
    ON ast.AS_STU_ID = s.STU_ID
WHERE UPPER(fah.AWARD_TYPE) LIKE '%MERIT%'
  AND ast.AS_STAT_CD = 'P'
ORDER BY s.STU_LNM, s.STU_FNM
FETCH FIRST 100 ROWS ONLY
```

**Result:** SQL Error — `ORA-00904: "XREF"."STU_ID": invalid identifier`

`STU_FA_XREF` was not in the retrieved set so its DDL was not available. The baseline guessed `STU_ID` as the join column — a natural English construction for a table with "student" in its name. The actual column is `SFX_STU_ID`, the 2015-era prefixed naming convention used throughout the cross-reference table. The query cannot execute.

---

### SchemaRAG (annotated) — Correct 5-Table Chain, 198 Rows

**Tables selected:** `ACAD_STAT_TBL, FA_AWARD_HISTORY, FINANCIAL_AID_APPLICATION, SCHOLARSHIP_POOL, STU_FA_XREF, STU_MST`

Note: `STU_FA_XREF` and `FINANCIAL_AID_APPLICATION` were added by SchemaRAG. The `[STU_MST JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→FA_AWARD_HISTORY]` annotation named the complete downstream chain, and the `[STU_FA_XREF BRIDGES FinancialAid:RegistrarCore]` annotation confirmed the bridge's role. With the DDL for `STU_FA_XREF` and `FINANCIAL_AID_APPLICATION` in context, the correct column names were available. The LLM used `TO_NUMBER(SUBSTR(sfx.SFX_FA_NBR, 3))` to strip the `FA` prefix from the display string and resolve the join to `FINANCIAL_AID_APPLICATION.FAA_ID` — a creative but correct inference enabled by the column comment documenting the format.

```sql
SELECT DISTINCT
    sm.STU_FNM, sm.STU_LNM, sm.STU_LVL, sm.STU_GPA,
    ast.AS_STAT_CD, ast.AS_TERM_CD, ast.AS_GPA_ACT,
    fah.AWARD_TYPE, fah.AWARD_AMOUNT, fah.AWARD_STATUS, fah.START_DATE
FROM UNIV_SCHEMARAG.STU_MST sm
JOIN UNIV_SCHEMARAG.ACAD_STAT_TBL ast
    ON ast.AS_STU_ID = sm.STU_ID
JOIN UNIV_SCHEMARAG.STU_FA_XREF sfx
    ON sfx.SFX_STU_ID = sm.STU_ID              -- ← correct: SFX_STU_ID is the actual column
JOIN UNIV_SCHEMARAG.FINANCIAL_AID_APPLICATION faa
    ON faa.FA_STU_KEY = sm.STU_ID
    AND faa.FAA_ID = TO_NUMBER(SUBSTR(sfx.SFX_FA_NBR, 3))  -- ← strips 'FA' prefix from VARCHAR2 display string
JOIN UNIV_SCHEMARAG.FA_AWARD_HISTORY fah
    ON fah.FAA_ID = faa.FAA_ID
WHERE ast.AS_STAT_CD = 'P'
  AND UPPER(fah.AWARD_TYPE) LIKE '%MERIT%'
  AND fah.AWARD_STATUS IS NOT NULL
  AND fah.CANCEL_DATE IS NULL
ORDER BY sm.STU_LNM, sm.STU_FNM
FETCH FIRST 100 ROWS ONLY
```

**Result:** 198 rows (total without limit: 198). Students with a SAP probation standing on record who hold active merit scholarship awards, showing academic standing term and GPA alongside the award type, amount, and status — exactly the list a financial aid director needs before the SAP review deadline.

---

### Why SchemaRAG Wins

**The baseline failed at the retrieval step and the join step simultaneously.** `STU_FA_XREF` was not selected because its name gives no vocabulary signal for "merit scholarship" or "financial aid bridge." The baseline retrieved `SCHOLARSHIP_POOL` instead — a plausible vocabulary match that is not in the required join chain. It then attempted to use `STU_FA_XREF` anyway (correctly sensing a cross-reference table was needed) but with invented column names and without `FINANCIAL_AID_APPLICATION` as the required intermediate.

**The bridge table is structurally invisible to DDL analysis.** `STU_FA_XREF` has no declared FK constraints. Its columns carry the `SFX_` prefix — `SFX_STU_ID`, `SFX_FA_NBR` — with no natural language analog. `SFX_FA_NBR` is a VARCHAR2 display string in the format `FA0000001`: not a numeric key, not directly joinable to any numeric FK column, and not documented in the original DDL. The only evidence that `STU_FA_XREF` bridges `STU_MST` to `FINANCIAL_AID_APPLICATION` exists in the workload — the application has always navigated this path. That workload evidence is captured in the STS, surfaced as graph annotations, and made available to the annotated retriever.

**Column format documentation prevented a type conversion error.** Before `COMMENT ON COLUMN stu_fa_xref.sfx_fa_nbr` was added, the LLM attempted `TO_NUMBER(sfx.SFX_FA_NBR) = faa.FAA_ID` and received `ORA-01722: invalid number` because the value `FA0000147` cannot be cast directly. The column comment — documenting `SFX_FA_NBR` as a VARCHAR2 display string in the format `FA` followed by 7 digits — gave the LLM enough information to derive `TO_NUMBER(SUBSTR(sfx.SFX_FA_NBR, 3))` as the correct conversion. This is the distinction between a relationship hint (which comments must not provide) and a data format hint (which is legitimate and necessary). The comment documents *what the value looks like*, not *which table it joins to*.

**The table comment that was there was worse than nothing.** The original DDL contained `COMMENT ON TABLE stu_fa_xref IS 'CRITICAL crosswalk: SFX_STU_ID=STU_MST.STU_ID, SFX_FA_NBR=FINANCIAL_AID_APPLICATION.FA_STU_KEY...'`. This comment was factually incorrect — `FA_STU_KEY` is a numeric student ID on `FINANCIAL_AID_APPLICATION`, not a match target for `SFX_FA_NBR` (the display string). The LLM read the comment, tried `TO_NUMBER(sfx.SFX_FA_NBR) = faa.FA_STU_KEY`, and got `ORA-01722`. A wrong relationship hint produced a wrong — and failing — query. The fix was to remove the table comment entirely and replace it with a column format comment only. Relationship knowledge belongs in SchemaRAG annotations, not in DDL comments.

**198 students at financial aid risk are visible only to the annotated side.** These are merit scholarship recipients who have fallen to SAP probation standing. Federal regulations require SAP monitoring for all aid recipients; institutional merit scholarship policies typically suspend or terminate awards after a probationary term. The financial aid office needs this list to initiate outreach, apply holds before disbursement, and schedule advising appointments before the packaging deadline. The baseline provides a SQL error; the annotated side provides 198 actionable rows.

---

### Join Path Illustrations

#### Standard RAG (baseline) — Bridge Table Missing, Invalid Column

The baseline selects `SCHOLARSHIP_POOL` from vocabulary match on "merit scholarships" and misses `STU_FA_XREF` entirely. It then attempts to use `STU_FA_XREF` anyway with an invented column name.

```
Question vocabulary:        Schema vocabulary:
"merit scholarships"   →    SCHOLARSHIP_POOL  ← wrong (pool definition, not awards)
"SAP probation"        →    ACAD_STAT_TBL     ← correct
"students"             →    STU_MST           ← correct
                            STU_FA_XREF       ← NOT RETRIEVED (name gives no signal)
                            FINANCIAL_AID_APPLICATION ← NOT RETRIEVED

STU_MST
    │
    │  xref.STU_ID = s.STU_ID  ← STU_ID does not exist on STU_FA_XREF
    ▼
STU_FA_XREF  (not retrieved — no DDL available)
    │
    │  fah.FAA_ID = xref.FAA_ID  ← FAA_ID does not exist on STU_FA_XREF
    ▼                               FINANCIAL_AID_APPLICATION not retrieved
FA_AWARD_HISTORY

ORA-00904: "XREF"."STU_ID": invalid identifier
```

**Result:** SQL error. Bridge table missing from retrieval, then two invented columns on an unretrieved table.

---

#### SchemaRAG (annotated) — 5-Table Chain via BRIDGES and JOINS_PATH

The `BRIDGES FinancialAid:RegistrarCore` annotation on `STU_FA_XREF` caused the retriever to include it. The `JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→FA_AWARD_HISTORY` annotation named the full downstream sequence including `FINANCIAL_AID_APPLICATION` as the required intermediate.

```
STU_MST  [IS_HUB degree:9.0] [BRIDGES Bursar:Curriculum:FinancialAid:RegistrarCore]
    │     [JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→FA_AWARD_HISTORY]
    │
    ├─── ast.AS_STU_ID = sm.STU_ID
    │    ▼
    │    ACAD_STAT_TBL
    │    (AS_STAT_CD = 'P')
    │
    └─── sfx.SFX_STU_ID = sm.STU_ID
         ▼
         STU_FA_XREF  ◄── BRIDGE (retrieved via BRIDGES FinancialAid:RegistrarCore annotation)
             │  [STU_FA_XREF BRIDGES FinancialAid:RegistrarCore]
             │  SFX_FA_NBR: VARCHAR2 'FA0000001' format  ← column comment: not a numeric key
             │
             │  faa.FA_STU_KEY = sm.STU_ID
             │  faa.FAA_ID = TO_NUMBER(SUBSTR(sfx.SFX_FA_NBR, 3))  ← strips 'FA' prefix
             ▼
             FINANCIAL_AID_APPLICATION  ◄── INTERMEDIATE (retrieved via JOINS_PATH annotation)
                 │  [FINANCIAL_AID_APPLICATION IS_HUB degree:4.0]
                 │
                 │  fah.FAA_ID = faa.FAA_ID
                 ▼
                 FA_AWARD_HISTORY
                 (AWARD_TYPE LIKE '%MERIT%'
                  CANCEL_DATE IS NULL)
```

**Result:** 198 rows. Merit scholarship recipients with SAP probation standing on record, with award details and academic standing term and GPA.

---

### Annotations Provided to the LLM

#### `STU_FA_XREF` — The Invisible Cross-Reference Bridge

```
[STU_FA_XREF BRIDGES FinancialAid:RegistrarCore]
[STU_FA_XREF JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION]
[STU_FA_XREF JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→FA_AWARD_HISTORY]
[STU_FA_XREF JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→NEED_ANALYSIS_RESULT]
[STU_FA_XREF JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→PELL_ELIGIBILITY_TBL]
[STU_FA_XREF IN_COMMUNITY FinancialAid]
[STU_FA_XREF JOINS_WITH STU_MST]
[STU_FA_XREF LOW_AFFINITY STU_MST:0.19]
[STU_FA_XREF JOINS_WITH FINANCIAL_AID_APPLICATION]
[STU_FA_XREF MEDIUM_AFFINITY FINANCIAL_AID_APPLICATION:0.21]
```

The `BRIDGES FinancialAid:RegistrarCore` annotation is the critical signal. It identifies `STU_FA_XREF` as the connection point between two communities — the retriever included it because the question spans both communities (merit aid = FinancialAid, SAP probation = RegistrarCore). The `JOINS_PATH` annotations name the complete downstream chain, including `FINANCIAL_AID_APPLICATION` as the required intermediate. Without these annotations, the table is invisible: its name contains no retrievable vocabulary, its columns carry opaque prefixes, and it has no FK constraints.

#### `STU_MST` — The Hub That Bridges Four Communities

```
[STU_MST JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→FA_AWARD_HISTORY]
[STU_MST JOINS_PATH STU_MST→STU_FA_XREF→FINANCIAL_AID_APPLICATION→NEED_ANALYSIS_RESULT]
[STU_MST JOINS_PATH STU_MST→ENRL_REC→ACAD_EXCEPTION_WRK]
[STU_MST BRIDGES Bursar:Curriculum:FinancialAid:RegistrarCore]
[STU_MST IN_COMMUNITY RegistrarCore]
[STU_MST IS_HUB degree:9.0]
[STU_MST JOINS_WITH STU_FA_XREF]
[STU_MST LOW_AFFINITY STU_FA_XREF:0.19]
[STU_MST JOINS_WITH ENRL_REC]
[STU_MST MEDIUM_AFFINITY ENRL_REC:0.38]
```

`STU_MST` carries the `JOINS_PATH` annotation naming `STU_FA_XREF` explicitly as the next hop. Both `STU_MST` and `STU_FA_XREF` carry the same downstream path annotation — the retriever saw convergent evidence from two independent starting points that `STU_FA_XREF` and `FINANCIAL_AID_APPLICATION` belong in the join chain. The `IS_HUB degree:9.0` annotation confirms this is the highest-degree node in the schema — any question involving students will route through this table, and its annotations pull in the downstream communities.

#### `FA_AWARD_HISTORY` — The Award Record

```
[FA_AWARD_HISTORY IN_COMMUNITY FinancialAid]
[FA_AWARD_HISTORY JOINS_WITH FINANCIAL_AID_APPLICATION]
[FA_AWARD_HISTORY HIGH_AFFINITY FINANCIAL_AID_APPLICATION:0.72]
[FA_AWARD_HISTORY JOINS_WITH SCHOLARSHIP_POOL]
[FA_AWARD_HISTORY MEDIUM_AFFINITY SCHOLARSHIP_POOL:0.41]
```

The `HIGH_AFFINITY FINANCIAL_AID_APPLICATION:0.72` annotation confirms the join between the award history and the application record is among the most frequent in the workload. This high affinity score tells the LLM that `FINANCIAL_AID_APPLICATION` is not an optional intermediate but the primary join target — these two tables are almost always queried together in production.

---

### What This Scenario Adds to the Demo

Scenario 5 introduces a failure mode distinct from the previous four:

**1. Table comment as misinformation.** The original DDL contained a table comment that documented the join relationship — but incorrectly. The LLM read the comment, used the documented join condition, and received a runtime error. This demonstrates that incorrect relationship hints in DDL are worse than no hints: they produce confident but wrong SQL that fails at execution rather than at parsing. Removing the table comment and replacing it with a column format comment (documenting the `FA` prefix format of `SFX_FA_NBR`) was more effective than correcting it — because the corrected comment would still violate the design principle that relationship knowledge belongs in SchemaRAG annotations, not in DDL.

**2. VARCHAR2 display string as join key.** `SFX_FA_NBR` stores `FA0000001` — a human-readable reference number, not a numeric FK. The join to `FINANCIAL_AID_APPLICATION.FAA_ID` requires stripping the `FA` prefix and casting to NUMBER. This is the kind of application-layer join logic that never appears in DDL and is invisible to any static analysis tool. The annotated side resolved it correctly via a column comment documenting the format — not a relationship hint, just a data format description.

**3. Cross-community SAP compliance query.** This is the first scenario that directly combines the RegistrarCore (academic standing) and FinancialAid (award history) communities in a compliance context. The business question is federally-mandated reporting — SAP monitoring for aid recipients — making the "198 invisible students" consequence immediate and regulatory rather than merely operational.

