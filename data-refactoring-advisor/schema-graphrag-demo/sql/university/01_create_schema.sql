-- Copyright (c) 2026, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

-- =============================================================================
-- Westfield University — Schema DDL
-- ~70 domain tables + 5 infrastructure tables, 10 communities, 9 naming eras
-- No FK constraints declared — referential integrity lives in application layer
--
-- Run by build_pipeline.py --schema university --step ddl
-- User creation and grants are handled by --step user
--
-- NAMING ERAS:
--   Era 1 (2007): RegistrarCore + Curriculum — 8-char COBOL-style, uppercase abbrev
--   Era 2 (2010): FinancialAid — verbose, mixed case conventions
--   Era 3 (2013): Legacy/PeopleSoft — PS_ prefix, mostly dead
--   Era 4 (2015): Bursar — BURS_ prefix
--   Era 5 (2016): HousingDining — HSG_ / DINING_ internal build
--   Era 6 (2018): Research — clean new + GRANT_ALLOC_WRK from grad student
--   Era 7 (2019): StudentServices + HR — readable but inconsistent
--   Era 8 (2020): Compliance/COVID contractor — ACAD_EXCEPTION_WRK, undocumented
--   Era 9 (2021): Compliance/Reporting — mix of styles, _WRK suffix for work tables
-- =============================================================================


-- =============================================================================
-- COMMUNITY 1: RegistrarCore — Era 1 (2007)
-- Original DBA from mainframe/COBOL. 8-char names, all uppercase abbreviated.
-- No comments. Referential integrity lived in PKG_REG_RULES (now deprecated).
-- =============================================================================

-- Master student table. STU_STAT_CD: A=Active, I=Inactive, W=Withdrawn, G=Graduated
-- Column STU_STAT_CD = 'W' means withdrawn from UNIVERSITY (not course withdrawal).
CREATE TABLE stu_mst (
    stu_id        NUMBER(10)   NOT NULL,
    stu_lnm       VARCHAR2(50) NOT NULL,
    stu_fnm       VARCHAR2(50) NOT NULL,
    stu_mnm       VARCHAR2(20),
    stu_dob       DATE         NOT NULL,
    stu_ssn       CHAR(9),
    stu_addr1     VARCHAR2(80),
    stu_addr2     VARCHAR2(80),
    stu_city      VARCHAR2(40),
    stu_st        CHAR(2),
    stu_zip       VARCHAR2(10),
    stu_email     VARCHAR2(100),
    stu_ph        VARCHAR2(20),
    stu_stat_cd   CHAR(1)      DEFAULT 'A',
    stu_lvl       VARCHAR2(10),
    stu_typ       CHAR(1),
    stu_adm_dt    DATE,
    stu_exp_grad  DATE,
    dept_id       NUMBER(6),
    stu_gpa       NUMBER(4,3),
    stu_hrs_att   NUMBER(5,1),
    stu_hrs_ernd  NUMBER(5,1),
    stu_honors    CHAR(1)      DEFAULT 'N',
    stu_resid     CHAR(1),
    stu_intl      CHAR(1)      DEFAULT 'N',
    upd_dt        DATE,
    CONSTRAINT pk_stu_mst PRIMARY KEY (stu_id)
);
-- Partial comment from 2007: "Student master. STU_STAT_CD see PKG_REG_RULES."
COMMENT ON TABLE stu_mst IS 'Student master record. STU_STAT_CD: A=Active I=Inactive W=Withdrawn G=Graduated';
COMMENT ON COLUMN stu_mst.stu_id IS 'Generated sequence - do not expose to users';
COMMENT ON COLUMN stu_mst.stu_stat_cd IS 'Student status: A=Active, I=Inactive, W=Withdrawn from university, G=Graduated';


-- Enrollment record. ER_STAT: R=Registered, W=Waitlisted, D=Dropped
-- ER_STAT = 'W' means WAITLISTED for a course (NOT withdrawn from university — that is STU_MST.STU_STAT_CD).
-- No comment was ever added to this table.
CREATE TABLE enrl_rec (
    er_id         NUMBER(12)   NOT NULL,
    er_stu_id     NUMBER(10)   NOT NULL,
    er_sect_id    NUMBER(8)    NOT NULL,
    er_term_cd    VARCHAR2(6)  NOT NULL,
    er_stat       CHAR(1)      DEFAULT 'R',
    er_crd_att    NUMBER(3,1),
    er_crd_ernd   NUMBER(3,1),
    er_grd_cd     VARCHAR2(4),
    er_grd_pts    NUMBER(4,2),
    er_enrl_dt    DATE,
    er_drop_dt    DATE,
    er_mid_grd    VARCHAR2(4),
    er_att_pct    NUMBER(5,2),
    er_fin_aid_fg VARCHAR2(1)  DEFAULT 'N',
    upd_dt        DATE,
    CONSTRAINT pk_enrl_rec PRIMARY KEY (er_id)
);
COMMENT ON COLUMN enrl_rec.er_stat IS 'Enrollment status: R=Registered, W=Waitlisted for course (not withdrawn from university), D=Dropped';


-- Grade history - snapshot of final grades per term. Not live data.
CREATE TABLE grd_hist (
    gh_id         NUMBER(12)   NOT NULL,
    gh_stu_id     NUMBER(10)   NOT NULL,
    gh_sect_id    NUMBER(8),
    gh_term_cd    VARCHAR2(6)  NOT NULL,
    gh_crs_nbr    VARCHAR2(12) NOT NULL,
    gh_grd_cd     VARCHAR2(4),
    gh_grd_pts    NUMBER(4,2),
    gh_crd_att    NUMBER(3,1),
    gh_crd_ernd   NUMBER(3,1),
    gh_repeat_fg  CHAR(1)      DEFAULT 'N',
    gh_post_dt    DATE,
    gh_instr_id   NUMBER(8),
    upd_dt        DATE,
    CONSTRAINT pk_grd_hist PRIMARY KEY (gh_id)
);
-- GRD_CD values (no comment): A/A-/B+/B/B-/C+/C/C-/D/F/W/I/P/NP/AU
COMMENT ON COLUMN grd_hist.gh_grd_cd IS 'Letter grade: A/A-/B+/B/B-/C+/C/C-/D/F=standard grades; W=Withdrew from course; I=Incomplete; P=Pass; NP=No Pass; AU=Audit';


-- Academic history - cumulative snapshot rebuilt nightly. NOT the source of truth.
-- ACAD_HIST is a reporting table. Live enrollment data is in GRD_HIST and ENRL_REC.
CREATE TABLE acad_hist (
    ah_id         NUMBER(10)   NOT NULL,
    ah_stu_id     NUMBER(10)   NOT NULL,
    ah_term_cd    VARCHAR2(6)  NOT NULL,
    ah_gpa_cum    NUMBER(4,3),
    ah_gpa_term   NUMBER(4,3),
    ah_hrs_att    NUMBER(5,1),
    ah_hrs_ernd   NUMBER(5,1),
    ah_class_lvl  VARCHAR2(10),
    ah_dean_lst   CHAR(1)      DEFAULT 'N',
    ah_prob_fg    CHAR(1)      DEFAULT 'N',
    ah_susp_fg    CHAR(1)      DEFAULT 'N',
    ah_snap_dt    DATE         NOT NULL,
    CONSTRAINT pk_acad_hist PRIMARY KEY (ah_id)
);


-- Term table - academic calendar. Same table since 2007.
CREATE TABLE term_tbl (
    term_cd       VARCHAR2(6)  NOT NULL,
    term_desc     VARCHAR2(40),
    term_start    DATE         NOT NULL,
    term_end      DATE         NOT NULL,
    reg_start     DATE,
    reg_end       DATE,
    add_drop_end  DATE,
    wthdr_end     DATE,
    grade_due     DATE,
    term_type     VARCHAR2(10),
    cal_yr        NUMBER(4),
    CONSTRAINT pk_term_tbl PRIMARY KEY (term_cd)
);


-- Academic standing table - used for SAP (Satisfactory Academic Progress) checks.
-- Bridges RegistrarCore AND FinancialAid — financial aid queries join this as often as registrar queries.
-- ACAD_STAT_CD: G=Good, P=Probation, S=Suspension, W=Warning (not Withdrawn — different from STU_MST)
CREATE TABLE acad_stat_tbl (
    as_id         NUMBER(10)   NOT NULL,
    as_stu_id     NUMBER(10)   NOT NULL,
    as_term_cd    VARCHAR2(6)  NOT NULL,
    as_stat_cd    CHAR(1)      NOT NULL,
    as_gpa_req    NUMBER(4,3),
    as_gpa_act    NUMBER(4,3),
    as_hrs_req    NUMBER(5,1),
    as_hrs_act    NUMBER(5,1),
    as_appeal_fg  CHAR(1)      DEFAULT 'N',
    as_appeal_dt  DATE,
    as_note       VARCHAR2(500),
    as_eff_dt     DATE,
    as_exp_dt     DATE,
    upd_dt        DATE,
    CONSTRAINT pk_acad_stat_tbl PRIMARY KEY (as_id)
);
-- No comment was added in 2007. Added in 2014 audit: "Acad standing. STAT_CD: G=Good P=Probation S=Suspension W=Warning"
COMMENT ON TABLE acad_stat_tbl IS 'Academic standing per student per term. STAT_CD: G=Good P=Probation S=Suspension W=Warning';
COMMENT ON COLUMN acad_stat_tbl.as_stat_cd IS 'Academic standing: G=Good Standing, P=Probation, S=Suspension, W=Warning';


-- =============================================================================
-- COMMUNITY 2: Curriculum — Era 1 (2007), same COBOL-style DBA, different owner
-- =============================================================================

-- Course catalog. CRS_STAT: A=Active, I=Inactive, D=Discontinued
CREATE TABLE crs_cat (
    crs_nbr       VARCHAR2(12) NOT NULL,
    crs_title     VARCHAR2(100),
    crs_desc      VARCHAR2(2000),
    crs_crd       NUMBER(3,1)  NOT NULL,
    dept_id       NUMBER(6)    NOT NULL,
    owner_dept_id NUMBER(6),
    crs_lvl       VARCHAR2(20),
    crs_stat      CHAR(1)      DEFAULT 'A',
    crs_typ       VARCHAR2(20),
    crs_eff_term  VARCHAR2(6),
    crs_exp_term  VARCHAR2(6),
    upd_dt        DATE,
    CONSTRAINT pk_crs_cat PRIMARY KEY (crs_nbr)
);
-- NOTE: CRS_CAT.DEPT_ID = offering department. OWNER_DEPT_ID = budget owner.
-- For cross-listed courses these differ. Workload queries reveal which to use per context.
COMMENT ON TABLE crs_cat IS 'Course catalog. DEPT_ID=offering dept, OWNER_DEPT_ID=budget owner. They differ for cross-listed courses.';
COMMENT ON COLUMN crs_cat.crs_stat IS 'Course catalog status: A=Active (offered), I=Inactive (not offered this term), D=Discontinued';


-- Course section — a specific offering in a term. Not course offerings (that is CRS_CAT).
-- CLASS_SCHED is instructor teaching assignments, not section offerings.
CREATE TABLE crs_sect (
    sect_id       NUMBER(8)    NOT NULL,
    crs_nbr       VARCHAR2(12) NOT NULL,
    term_cd       VARCHAR2(6)  NOT NULL,
    sect_nbr      VARCHAR2(4),
    instr_id      NUMBER(8),
    room_id       NUMBER(6),
    dept_id       NUMBER(6),
    max_enrl      NUMBER(4)    DEFAULT 30,
    cur_enrl      NUMBER(4)    DEFAULT 0,
    waitlist_cnt  NUMBER(4)    DEFAULT 0,
    meet_days     VARCHAR2(10),
    meet_start    VARCHAR2(8),
    meet_end      VARCHAR2(8),
    deliv_mode    VARCHAR2(20),
    sect_stat     CHAR(1)      DEFAULT 'A',
    upd_dt        DATE,
    CONSTRAINT pk_crs_sect PRIMARY KEY (sect_id)
);


-- Department table. DEPT_ID appears in 8 different tables with 8 slightly different meanings.
CREATE TABLE dept_tbl (
    dept_id       NUMBER(6)    NOT NULL,
    dept_cd       VARCHAR2(10) NOT NULL UNIQUE,
    dept_nm       VARCHAR2(80) NOT NULL,
    coll_id       NUMBER(4),
    dept_head_id  NUMBER(8),
    dept_email    VARCHAR2(100),
    dept_ph       VARCHAR2(20),
    dept_loc      VARCHAR2(50),
    dept_stat     CHAR(1)      DEFAULT 'A',
    dept_type     VARCHAR2(20),
    upd_dt        DATE,
    CONSTRAINT pk_dept_tbl PRIMARY KEY (dept_id)
);
COMMENT ON TABLE dept_tbl IS 'Academic department.';


-- Instructor table. INSTR_ID is the registrar key for a person who teaches.
-- Same person may appear in STAFF_HR_XREF as SHX_HR_EMP_ID and in FACULTY_APPT as FA_APPT_ID.
CREATE TABLE instr_tbl (
    instr_id      NUMBER(8)    NOT NULL,
    instr_lnm     VARCHAR2(50) NOT NULL,
    instr_fnm     VARCHAR2(50) NOT NULL,
    dept_id       NUMBER(6),
    instr_email   VARCHAR2(100),
    instr_rank    VARCHAR2(30),
    instr_ten_fg  CHAR(1)      DEFAULT 'N',
    instr_stat    CHAR(1)      DEFAULT 'A',
    hire_dt       DATE,
    upd_dt        DATE,
    CONSTRAINT pk_instr_tbl PRIMARY KEY (instr_id)
);


-- Room inventory. Despite name implies facilities, this is owned by Curriculum.
-- ROOM_INVT is always queried for scheduling, never for maintenance.
CREATE TABLE room_invt (
    room_id       NUMBER(6)    NOT NULL,
    room_nbr      VARCHAR2(20) NOT NULL,
    bldg_cd       VARCHAR2(10),
    room_cap      NUMBER(4),
    room_typ      VARCHAR2(20),
    room_feat     VARCHAR2(200),
    campus_cd     VARCHAR2(5),
    room_stat     CHAR(1)      DEFAULT 'A',
    upd_dt        DATE,
    CONSTRAINT pk_room_invt PRIMARY KEY (room_id)
);
COMMENT ON TABLE room_invt IS 'Room inventory for scheduling. Owned by Curriculum, not Facilities — despite the name.';


-- Course prerequisites. Self-referencing against CRS_CAT.
CREATE TABLE crs_prereq (
    prereq_id     NUMBER(8)    NOT NULL,
    crs_nbr       VARCHAR2(12) NOT NULL,
    prereq_crs    VARCHAR2(12) NOT NULL,
    min_grade     VARCHAR2(4),
    conc_ok       CHAR(1)      DEFAULT 'N',
    prereq_type   VARCHAR2(20) DEFAULT 'REQUIRED',
    eff_term      VARCHAR2(6),
    upd_dt        DATE,
    CONSTRAINT pk_crs_prereq PRIMARY KEY (prereq_id)
);


-- Class schedule — instructor teaching assignments per term.
-- NOT course section offerings (that is CRS_SECT). The name is misleading.
CREATE TABLE class_sched (
    cs_id         NUMBER(8)    NOT NULL,
    instr_id      NUMBER(8)    NOT NULL,
    sect_id       NUMBER(8)    NOT NULL,
    term_cd       VARCHAR2(6)  NOT NULL,
    assign_dt     DATE,
    assign_hrs    NUMBER(4,1),
    assign_type   VARCHAR2(20),
    prim_instr_fg CHAR(1)      DEFAULT 'Y',
    upd_dt        DATE,
    CONSTRAINT pk_class_sched PRIMARY KEY (cs_id)
);
COMMENT ON TABLE class_sched IS 'Instructor teaching assignments.';


-- Scheduling optimizer work table — Era 9 addition, lives in Curriculum community.
-- Created by Reporting team to track room/time conflicts during registration.
-- _WRK: no table comment, opaque columns, no FKs declared.
CREATE TABLE sched_optim_wrk (
    sow_id        NUMBER(10)   NOT NULL,
    sow_sect_id   NUMBER(8),
    sow_room_id   NUMBER(6),
    sow_term_cd   VARCHAR2(6),
    sow_conf_type VARCHAR2(20),
    sow_conf_sev  CHAR(1),
    sow_res_stat  CHAR(1),
    sow_run_dt    DATE,
    sow_notes     VARCHAR2(1000),
    CONSTRAINT pk_sched_optim_wrk PRIMARY KEY (sow_id)
);


-- Transfer institution map — Era 9, lives in Curriculum + RegistrarCore boundary.
-- Crosswalk: XIM_CRS_NBR (internal course number) ↔ XIM_EXT_CRS_CD (external course code).
CREATE TABLE xfer_inst_map (
    xim_id        NUMBER(10)   NOT NULL,
    xim_inst_cd   VARCHAR2(20) NOT NULL,
    xim_inst_nm   VARCHAR2(200),
    xim_crs_nbr   VARCHAR2(12),
    xim_ext_crs_cd VARCHAR2(30),
    xim_eq_type   VARCHAR2(10),
    xim_crd_equiv NUMBER(3,1),
    xim_eff_term  VARCHAR2(6),
    xim_exp_term  VARCHAR2(6),
    xim_aprv_dt   DATE,
    xim_aprv_by   NUMBER(8),
    CONSTRAINT pk_xfer_inst_map PRIMARY KEY (xim_id)
);
COMMENT ON TABLE xfer_inst_map IS 'Transfer equivalency crosswalk. XIM_CRS_NBR=internal, XIM_EXT_CRS_CD=sending institution code.';


-- =============================================================================
-- COMMUNITY 3: FinancialAid — Era 2 (2010–2013)
-- Absorbed from vendor. Verbose naming, partial FK comments, no actual FK constraints.
-- =============================================================================

-- Main financial aid application. STATUS: A=Awarded, D=Denied, P=Pending (not same as STU_MST)
CREATE TABLE financial_aid_application (
    faa_id              NUMBER(10)   NOT NULL,
    fa_stu_key          NUMBER(10)   NOT NULL,
    aid_year            NUMBER(4)    NOT NULL,
    application_date    DATE,
    verification_status VARCHAR2(20),
    efc_amount          NUMBER(10,2),
    status              VARCHAR2(10) DEFAULT 'P',
    status_date         DATE,
    dependency_status   VARCHAR2(15),
    housing_plan        VARCHAR2(20),
    enrollment_level    VARCHAR2(10),
    fafsa_receipt_dt    DATE,
    isir_transaction_nbr NUMBER(2),
    upd_dt              DATE,
    CONSTRAINT pk_fin_aid_app PRIMARY KEY (faa_id)
);
-- STATUS values here: A=Awarded D=Denied P=Pending — completely different from BURS_STUDENT_ACCOUNT.STATUS
COMMENT ON TABLE financial_aid_application IS 'FAFSA-based aid application per student per aid year. STATUS: A=Awarded D=Denied P=Pending.';
COMMENT ON COLUMN financial_aid_application.status IS 'Application status: A=Awarded, D=Denied, P=Pending.';


-- Award history - what was actually disbursed
CREATE TABLE fa_award_history (
    award_id        NUMBER(10)   NOT NULL,
    faa_id          NUMBER(10)   NOT NULL,
    aid_year        NUMBER(4),
    award_type      VARCHAR2(30) NOT NULL,
    fund_source     VARCHAR2(30),
    offered_amount  NUMBER(10,2),
    accepted_amount NUMBER(10,2),
    disbursed_amount NUMBER(10,2),
    award_status    VARCHAR2(15) DEFAULT 'OFFERED',
    offer_date      DATE,
    accept_date     DATE,
    disb_date       DATE,
    cancel_date     DATE,
    upd_dt          DATE,
    CONSTRAINT pk_fa_award_hist PRIMARY KEY (award_id)
);
COMMENT ON TABLE fa_award_history IS 'Aid awards per application. AWARD_TYPE includes PELL, SUBSIDIZED, UNSUBSIDIZED, INSTITUTIONAL, SCHOLARSHIP.';
COMMENT ON COLUMN fa_award_history.award_type IS 'Award type code: MERIT_SCHOLARSHIP, NEED_SCHOLARSHIP, PELL, SUBSIDIZED, UNSUBSIDIZED, INSTITUTIONAL, WORK_STUDY';


-- Scholarship pool - available institutional aid
CREATE TABLE scholarship_pool (
    scholarship_id    NUMBER(8)    NOT NULL,
    scholarship_name  VARCHAR2(100) NOT NULL,
    scholarship_type  VARCHAR2(30),
    fund_amount       NUMBER(12,2),
    renewable         CHAR(1)      DEFAULT 'N',
    min_gpa           NUMBER(4,3),
    min_credit_hrs    NUMBER(3,1),
    dept_restriction  NUMBER(6),
    residency_req     CHAR(1),
    merit_based       CHAR(1)      DEFAULT 'N',
    need_based        CHAR(1)      DEFAULT 'N',
    active            CHAR(1)      DEFAULT 'Y',
    upd_dt            DATE,
    CONSTRAINT pk_scholarship_pool PRIMARY KEY (scholarship_id)
);
COMMENT ON TABLE scholarship_pool IS 'Institutional scholarship fund definitions.';


-- Loan disbursement tracking. STATUS: S=Scheduled, H=Hold, R=Released, C=Cancelled
CREATE TABLE loan_disbursement (
    disb_id           NUMBER(10)   NOT NULL,
    award_id          NUMBER(10)   NOT NULL,
    loan_type         VARCHAR2(20),
    disb_seq_nbr      NUMBER(2),
    disb_amount       NUMBER(10,2),
    status            VARCHAR2(10) DEFAULT 'S',
    sched_date        DATE,
    actual_date       DATE,
    hold_reason       VARCHAR2(100),
    lender_id         VARCHAR2(20),
    servicer_id       VARCHAR2(20),
    upd_dt            DATE,
    CONSTRAINT pk_loan_disb PRIMARY KEY (disb_id)
);
-- STATUS here: S=Scheduled H=Hold R=Released C=Cancelled — 4 values, different from all other STATUS columns
COMMENT ON COLUMN loan_disbursement.status IS 'Disbursement status: S=Scheduled, H=Hold, R=Released, C=Cancelled';


-- Need analysis results from FAFSA processing
CREATE TABLE need_analysis_result (
    nar_id             NUMBER(10)   NOT NULL,
    faa_id             NUMBER(10)   NOT NULL,
    nar_run_date       DATE         NOT NULL,
    efc_federal        NUMBER(10,2),
    efc_institutional  NUMBER(10,2),
    coa_on_campus      NUMBER(10,2),
    coa_off_campus     NUMBER(10,2),
    unmet_need_federal NUMBER(10,2),
    unmet_need_inst    NUMBER(10,2),
    pell_eligible      CHAR(1)      DEFAULT 'N',
    auto_zero_efc      CHAR(1)      DEFAULT 'N',
    simplified_needs   CHAR(1)      DEFAULT 'N',
    notes              VARCHAR2(1000),
    upd_dt             DATE,
    CONSTRAINT pk_need_analysis PRIMARY KEY (nar_id)
);
COMMENT ON TABLE need_analysis_result IS 'Calculated financial need per FAFSA application. COA = Cost of Attendance.';


-- Aid packaging rules - institutional policy table
CREATE TABLE aid_packaging_rule (
    rule_id          NUMBER(8)    NOT NULL,
    rule_name        VARCHAR2(100),
    rule_type        VARCHAR2(30),
    aid_year         NUMBER(4),
    eligibility_expr VARCHAR2(500),
    award_sequence   NUMBER(3),
    max_award_pct    NUMBER(5,2),
    active           CHAR(1)      DEFAULT 'Y',
    eff_date         DATE,
    exp_date         DATE,
    upd_dt           DATE,
    CONSTRAINT pk_aid_pkg_rule PRIMARY KEY (rule_id)
);


-- Pell eligibility table - federal program tracking
CREATE TABLE pell_eligibility_tbl (
    pell_id          NUMBER(10)   NOT NULL,
    faa_id           NUMBER(10)   NOT NULL,
    aid_year         NUMBER(4),
    lifetime_units   NUMBER(4,3),
    max_lifetime_units NUMBER(4,3) DEFAULT 6.0,
    pell_grant_amount NUMBER(10,2),
    enrollment_intensity VARCHAR2(20),
    disbursement_schedule NUMBER(3),
    upd_dt           DATE,
    CONSTRAINT pk_pell_elig PRIMARY KEY (pell_id)
);


-- STU_FA_XREF — crosswalk between registrar student IDs and financial aid vendor numbers.
-- The join column names are DIFFERENT on each side — this is the bridge.
-- Documented only in a Word file on a SharePoint requiring VPN.
CREATE TABLE stu_fa_xref (
    sfx_id        NUMBER(10)   NOT NULL,
    sfx_stu_id    NUMBER(10)   NOT NULL,
    sfx_fa_nbr    VARCHAR2(20) NOT NULL,
    sfx_eff_dt    DATE         NOT NULL,
    sfx_exp_dt    DATE,
    sfx_xref_typ  VARCHAR2(10) DEFAULT 'PRIMARY',
    sfx_cre_dt    DATE,
    CONSTRAINT pk_stu_fa_xref PRIMARY KEY (sfx_id)
);
COMMENT ON COLUMN stu_fa_xref.sfx_fa_nbr IS 'Human-readable FA reference string in format FA followed by 7 digits, e.g. FA0000001. VARCHAR2 display identifier — not a numeric key, do not cast to NUMBER.';


-- =============================================================================
-- COMMUNITY 4: Legacy/PeopleSoft — Era 3 (2013–2016)
-- $4M project, cancelled at 60%. Contains real data from 2013–2016.
-- Low affinity with active tables — these are zombie tables.
-- =============================================================================

-- PeopleSoft student enrollment — overlaps with ENRL_REC concept but different structure
CREATE TABLE ps_stdnt_enrl (
    emplid        VARCHAR2(11) NOT NULL,
    acad_career   VARCHAR2(4),
    strm          VARCHAR2(4),
    class_nbr     NUMBER(5),
    unt_taken     NUMBER(6,3),
    grade         VARCHAR2(4),
    grading_basis VARCHAR2(3),
    enrl_status   VARCHAR2(2),
    stdnt_enrl_status VARCHAR2(2),
    last_enrl_dt  DATE,
    CONSTRAINT pk_ps_stdnt_enrl PRIMARY KEY (emplid, strm, class_nbr)
);
COMMENT ON TABLE ps_stdnt_enrl IS 'PeopleSoft 2013-2016 student enrollment. Zombie table — do not use for current data.';


-- PeopleSoft class table — overlaps with CRS_SECT
CREATE TABLE ps_class_tbl (
    class_nbr     NUMBER(5)    NOT NULL,
    strm          VARCHAR2(4),
    subject       VARCHAR2(4),
    catalog_nbr   VARCHAR2(10),
    section       VARCHAR2(4),
    instruction_mode VARCHAR2(2),
    enrl_cap      NUMBER(4),
    enrl_tot      NUMBER(4),
    CONSTRAINT pk_ps_class_tbl PRIMARY KEY (class_nbr, strm)
);
COMMENT ON TABLE ps_class_tbl IS 'PeopleSoft 2013-2016 class table. Zombie — do not use for current data.';


-- PeopleSoft academic plan
CREATE TABLE ps_acad_plan (
    emplid        VARCHAR2(11) NOT NULL,
    acad_career   VARCHAR2(4),
    acad_plan     VARCHAR2(10),
    req_term      VARCHAR2(4),
    eff_date      DATE,
    CONSTRAINT pk_ps_acad_plan PRIMARY KEY (emplid, acad_career, acad_plan)
);


-- PeopleSoft term table — same concept as TERM_TBL, different structure
CREATE TABLE ps_term_tbl (
    strm          VARCHAR2(4)  NOT NULL,
    descr         VARCHAR2(30),
    begin_dt      DATE,
    end_dt        DATE,
    acad_year     VARCHAR2(4),
    CONSTRAINT pk_ps_term_tbl PRIMARY KEY (strm)
);
COMMENT ON TABLE ps_term_tbl IS 'PeopleSoft term table. Zombie — do not use for current data.';


-- PeopleSoft student degree progress
CREATE TABLE ps_stdnt_degr (
    emplid        VARCHAR2(11) NOT NULL,
    acad_career   VARCHAR2(4),
    acad_plan     VARCHAR2(10),
    degree        VARCHAR2(10),
    degree_status VARCHAR2(2),
    confer_dt     DATE,
    CONSTRAINT pk_ps_stdnt_degr PRIMARY KEY (emplid, acad_career, acad_plan)
);


-- Old grade archive — pre-2009 paper grade records digitized in 2011
CREATE TABLE old_grade_arch (
    arch_id       NUMBER(10)   NOT NULL,
    legacy_stu_id VARCHAR2(15),
    legacy_crs_cd VARCHAR2(15),
    term_yr       NUMBER(4),
    term_sem      VARCHAR2(6),
    grade_ltr     CHAR(2),
    grade_pts     NUMBER(4,2),
    digitize_dt   DATE,
    digitize_by   VARCHAR2(30),
    CONSTRAINT pk_old_grade_arch PRIMARY KEY (arch_id)
);
COMMENT ON TABLE old_grade_arch IS 'Pre-2009 grade archive. Historical reference only.';


-- Legacy course table — pre-2007 course catalog
CREATE TABLE legacy_crs_tbl (
    lct_id        NUMBER(8)    NOT NULL,
    old_crs_cd    VARCHAR2(15),
    old_crs_nm    VARCHAR2(100),
    old_dept_cd   VARCHAR2(10),
    crd_hrs       NUMBER(3,1),
    disc_yr       NUMBER(4),
    CONSTRAINT pk_legacy_crs_tbl PRIMARY KEY (lct_id)
);
COMMENT ON TABLE legacy_crs_tbl IS 'Pre-2007 course catalog archive. Zombie table — do not use for current data.';


-- =============================================================================
-- COMMUNITY 5: Bursar — Era 4 (2015–2017)
-- Separate vendor. BURS_ prefix. STUDENT_NBR = STU_MST.STU_ID (same value, documented only in comment).
-- STATUS on BURS_STUDENT_ACCOUNT: C=Current, D=Delinquent, S=Suspended — entirely different STATUS domain.
-- =============================================================================

-- Student billing account. STATUS: C=Current, D=Delinquent, S=Suspended
-- STUDENT_NBR = STU_MST.STU_ID (different column name, same value)
CREATE TABLE burs_student_account (
    bsa_id          NUMBER(10)   NOT NULL,
    student_nbr     NUMBER(10)   NOT NULL,
    acct_open_dt    DATE         NOT NULL,
    acct_status     VARCHAR2(10) DEFAULT 'C',
    current_balance NUMBER(12,2) DEFAULT 0,
    past_due_amt    NUMBER(12,2) DEFAULT 0,
    credit_limit    NUMBER(10,2),
    payment_plan_fg CHAR(1)      DEFAULT 'N',
    last_stmt_dt    DATE,
    last_pmt_dt     DATE,
    last_pmt_amt    NUMBER(10,2),
    upd_dt          DATE,
    CONSTRAINT pk_burs_stu_acct PRIMARY KEY (bsa_id)
);
-- KEY DOCUMENTATION: STUDENT_NBR = STU_MST.STU_ID (not declared as FK)
COMMENT ON TABLE burs_student_account IS 'Bursar student billing account. ACCT_STATUS: C=Current D=Delinquent S=Suspended.';
COMMENT ON COLUMN burs_student_account.acct_status IS 'Account status: C=Current (in good standing), D=Delinquent (past due), S=Suspended (services blocked)';


-- Individual charges on the account
CREATE TABLE burs_charge_line (
    bcl_id          NUMBER(12)   NOT NULL,
    bsa_id          NUMBER(10)   NOT NULL,
    billing_period_id NUMBER(8),
    charge_type     VARCHAR2(30) NOT NULL,
    charge_desc     VARCHAR2(200),
    charge_amount   NUMBER(10,2) NOT NULL,
    charge_date     DATE         NOT NULL,
    due_date        DATE,
    term_cd         VARCHAR2(6),
    waived_fg       CHAR(1)      DEFAULT 'N',
    waive_reason    VARCHAR2(100),
    upd_dt          DATE,
    CONSTRAINT pk_burs_charge_line PRIMARY KEY (bcl_id)
);


-- Payments received
CREATE TABLE burs_payment (
    bpmt_id         NUMBER(12)   NOT NULL,
    bsa_id          NUMBER(10)   NOT NULL,
    pmt_date        DATE         NOT NULL,
    pmt_method      VARCHAR2(20),
    pmt_amount      NUMBER(10,2) NOT NULL,
    pmt_reference   VARCHAR2(50),
    pmt_source      VARCHAR2(30),
    applied_fg      CHAR(1)      DEFAULT 'Y',
    upd_dt          DATE,
    CONSTRAINT pk_burs_payment PRIMARY KEY (bpmt_id)
);


-- Refund requests
CREATE TABLE burs_refund_request (
    brr_id          NUMBER(10)   NOT NULL,
    bsa_id          NUMBER(10)   NOT NULL,
    req_date        DATE         NOT NULL,
    req_amount      NUMBER(10,2),
    refund_reason   VARCHAR2(100),
    refund_method   VARCHAR2(20),
    refund_status   VARCHAR2(15) DEFAULT 'PENDING',
    process_date    DATE,
    check_nbr       VARCHAR2(20),
    upd_dt          DATE,
    CONSTRAINT pk_burs_refund_req PRIMARY KEY (brr_id)
);


-- Tuition rate schedule — term/student-type/residency combinations
CREATE TABLE burs_tuition_rate (
    btr_id          NUMBER(8)    NOT NULL,
    term_cd         VARCHAR2(6)  NOT NULL,
    student_type    VARCHAR2(20),
    residency_cd    CHAR(1),
    credit_band_lo  NUMBER(3,1),
    credit_band_hi  NUMBER(3,1),
    rate_per_credit NUMBER(8,2),
    flat_rate       NUMBER(10,2),
    eff_dt          DATE,
    exp_dt          DATE,
    upd_dt          DATE,
    CONSTRAINT pk_burs_tuition_rate PRIMARY KEY (btr_id)
);
COMMENT ON TABLE burs_tuition_rate IS 'Tuition rate schedule by term, student type, and residency. CREDIT_BAND_LO/HI define flat-rate brackets.';


-- Billing period definitions (semester, summer, etc.)
CREATE TABLE burs_billing_period (
    billing_period_id NUMBER(8)  NOT NULL,
    period_name     VARCHAR2(50),
    term_cd         VARCHAR2(6),
    bill_start_dt   DATE,
    bill_end_dt     DATE,
    due_date        DATE,
    late_fee_pct    NUMBER(5,2),
    active          CHAR(1)      DEFAULT 'Y',
    CONSTRAINT pk_burs_billing_period PRIMARY KEY (billing_period_id)
);


-- Installment plan definitions
CREATE TABLE burs_installment_plan (
    bip_id          NUMBER(8)    NOT NULL,
    bsa_id          NUMBER(10)   NOT NULL,
    plan_type       VARCHAR2(30),
    billing_period_id NUMBER(8),
    total_amount    NUMBER(10,2),
    installments    NUMBER(2),
    first_pmt_dt    DATE,
    pmt_interval    VARCHAR2(10),
    plan_status     VARCHAR2(15) DEFAULT 'ACTIVE',
    enrollment_fee  NUMBER(8,2),
    upd_dt          DATE,
    CONSTRAINT pk_burs_install_plan PRIMARY KEY (bip_id)
);


-- Bursar hold codes — this is a REFERENCE TABLE of hold types, not student hold records.
-- STUDENT_HOLDS (a different table you might expect) is actually hold type config, not individual records.
-- Individual student holds are tracked via BURS_HOLD_CODE rows joined to BURS_STUDENT_ACCOUNT.
-- This table bridges Bursar AND Compliance — degree audit queries join it as often as billing queries.
CREATE TABLE burs_hold_code (
    hold_code       VARCHAR2(10) NOT NULL,
    hold_desc       VARCHAR2(100),
    hold_type       VARCHAR2(20),
    prevent_reg     CHAR(1)      DEFAULT 'N',
    prevent_grades  CHAR(1)      DEFAULT 'N',
    prevent_diploma CHAR(1)      DEFAULT 'N',
    auto_release    CHAR(1)      DEFAULT 'N',
    dept_owner      NUMBER(6),
    active          CHAR(1)      DEFAULT 'Y',
    CONSTRAINT pk_burs_hold_code PRIMARY KEY (hold_code)
);
COMMENT ON TABLE burs_hold_code IS 'Bursar hold type reference table (configuration).';


-- Student holds — junction between accounts and hold codes
CREATE TABLE burs_student_hold (
    bsh_id          NUMBER(10)   NOT NULL,
    bsa_id          NUMBER(10)   NOT NULL,
    hold_code       VARCHAR2(10) NOT NULL,
    placed_dt       DATE         NOT NULL,
    placed_by       NUMBER(8),
    released_dt     DATE,
    released_by     NUMBER(8),
    hold_amt        NUMBER(10,2),
    hold_notes      VARCHAR2(500),
    CONSTRAINT pk_burs_stu_hold PRIMARY KEY (bsh_id)
);


-- Tuition appeal work table — Era 9, lives in Bursar community.
-- TAW_APPEAL_CD: FIN_HARD=Financial Hardship, MED_EMRG=Medical Emergency,
--               SVCE_ERR=Service Error, SCHL_ERR=Scheduling Error — NO COMMENT on table.
-- _WRK table: no table comment, undocumented codes, no FK declared.
CREATE TABLE tutn_appeal_wrk (
    taw_id          NUMBER(10)   NOT NULL,
    taw_acct_ref    NUMBER(10),
    taw_term_cd     VARCHAR2(6),
    taw_appeal_cd   VARCHAR2(10),
    taw_appeal_dt   DATE,
    taw_credit_amt  NUMBER(10,2),
    taw_stat_flg    CHAR(1),
    taw_reviewer    NUMBER(8),
    taw_review_dt   DATE,
    taw_doc_url     VARCHAR2(500),
    taw_notes       VARCHAR2(2000),
    CONSTRAINT pk_tutn_appeal_wrk PRIMARY KEY (taw_id)
);
-- NO COMMENT on this table — intentional. Codes undocumented.
-- TAW_ACCT_REF = BURS_STUDENT_ACCOUNT.BSA_ID (same value, different name)
-- TAW_STAT_FLG: P=Pending, A=Approved, D=Denied, W=Withdrawn — undocumented


-- =============================================================================
-- COMMUNITY 6: HousingDining — Era 5 (2016–2018)
-- Built internally. Shows. HSG_ and DINING_ prefixes.
-- _WRK suffix = work/control table, selected by whoever was on call that Thursday.
-- =============================================================================

-- Room inventory for residential halls (different from ROOM_INVT which is for classrooms)
CREATE TABLE hsg_room_inventory (
    hsg_room_id   NUMBER(8)    NOT NULL,
    bldg_cd       VARCHAR2(10) NOT NULL,
    room_nbr      VARCHAR2(10),
    room_type     VARCHAR2(20),
    capacity      NUMBER(2)    DEFAULT 2,
    gender_assn   CHAR(1),
    floor_nbr     NUMBER(2),
    amenities     VARCHAR2(200),
    rate_per_sem  NUMBER(8,2),
    room_status   VARCHAR2(15) DEFAULT 'AVAILABLE',
    upd_dt        DATE,
    CONSTRAINT pk_hsg_room_inv PRIMARY KEY (hsg_room_id)
);
COMMENT ON TABLE hsg_room_inventory IS 'Residential hall rooms. Different from ROOM_INVT (classroom scheduling).';


-- Room assignments — who is in which dorm room
CREATE TABLE hsg_room_assignment (
    hra_id        NUMBER(10)   NOT NULL,
    hsg_room_id   NUMBER(8)    NOT NULL,
    student_id    NUMBER(10)   NOT NULL,
    term_cd       VARCHAR2(6)  NOT NULL,
    assignment_dt DATE         NOT NULL,
    check_in_dt   DATE,
    check_out_dt  DATE,
    assignment_type VARCHAR2(20),
    roommate_pref VARCHAR2(500),
    upd_dt        DATE,
    CONSTRAINT pk_hsg_room_asgn PRIMARY KEY (hra_id)
);
-- STUDENT_ID = STU_MST.STU_ID (yet another column name for the same student key)
COMMENT ON TABLE hsg_room_assignment IS 'Active dorm room assignments.';


-- Housing contracts — financial agreement for housing
CREATE TABLE hsg_contract (
    hsg_con_id    NUMBER(10)   NOT NULL,
    student_id    NUMBER(10)   NOT NULL,
    term_cd       VARCHAR2(6),
    contract_type VARCHAR2(20),
    contract_amt  NUMBER(8,2),
    sign_dt       DATE,
    cancel_dt     DATE,
    cancel_reason VARCHAR2(100),
    status        VARCHAR2(10) DEFAULT 'A',
    upd_dt        DATE,
    CONSTRAINT pk_hsg_contract PRIMARY KEY (hsg_con_id)
);
-- STATUS: A=Active, E=Expired, T=Terminated — different STATUS domain again
COMMENT ON TABLE hsg_contract IS 'Housing contract per student per term. STATUS: A=Active E=Expired T=Terminated.';
COMMENT ON COLUMN hsg_contract.status IS 'Contract status: A=Active, E=Expired (term ended), T=Terminated (early exit)';


-- Waitlist work table — queue for housing assignment.
-- HSG_WAITLIST_WRK is a _WRK table: columns selected by whoever was available.
-- No table comment. No FK declared. HWW_STU_REF = STU_MST.STU_ID.
CREATE TABLE hsg_waitlist_wrk (
    hww_id        NUMBER(10)   NOT NULL,
    hww_stu_ref   NUMBER(10),
    hww_term_cd   VARCHAR2(6),
    hww_req_type  VARCHAR2(20),
    hww_pref_bldg VARCHAR2(10),
    hww_pref_room VARCHAR2(20),
    hww_priority  NUMBER(3),
    hww_stat_cd   CHAR(1),
    hww_req_dt    DATE,
    hww_exp_dt    DATE,
    hww_notes     VARCHAR2(1000),
    CONSTRAINT pk_hsg_waitlist_wrk PRIMARY KEY (hww_id)
);
-- HWW_STAT_CD: A=Active, O=Offered, X=Expired, C=Cancelled — no comment
COMMENT ON COLUMN hsg_waitlist_wrk.hww_stat_cd IS 'Waitlist status: A=Active (waiting), O=Offered (room offered, awaiting response), X=Expired (offer lapsed), C=Cancelled';


-- Dining plans — meal plan registration
CREATE TABLE dining_plan (
    dp_id         NUMBER(8)    NOT NULL,
    student_id    NUMBER(10)   NOT NULL,
    term_cd       VARCHAR2(6)  NOT NULL,
    plan_type     VARCHAR2(20),
    meals_per_wk  NUMBER(2),
    flex_dollars  NUMBER(8,2),
    plan_cost     NUMBER(8,2),
    start_dt      DATE,
    end_dt        DATE,
    plan_status   VARCHAR2(15) DEFAULT 'ACTIVE',
    upd_dt        DATE,
    CONSTRAINT pk_dining_plan PRIMARY KEY (dp_id)
);


-- Dining transactions — swipes, flex dollars, etc.
CREATE TABLE dining_transaction (
    dt_id         NUMBER(12)   NOT NULL,
    dp_id         NUMBER(8)    NOT NULL,
    location_id   NUMBER(6),
    trans_dt      TIMESTAMP    NOT NULL,
    trans_type    VARCHAR2(20),
    meal_count    NUMBER(2)    DEFAULT 0,
    flex_amt      NUMBER(6,2)  DEFAULT 0,
    balance_after NUMBER(8,2),
    CONSTRAINT pk_dining_trans PRIMARY KEY (dt_id)
);


-- Dining locations
CREATE TABLE dining_location (
    location_id   NUMBER(6)    NOT NULL,
    location_name VARCHAR2(80) NOT NULL,
    bldg_cd       VARCHAR2(10),
    meal_types    VARCHAR2(50),
    hours_mon_fri VARCHAR2(30),
    hours_wknd    VARCHAR2(30),
    active        CHAR(1)      DEFAULT 'Y',
    CONSTRAINT pk_dining_location PRIMARY KEY (location_id)
);


-- =============================================================================
-- COMMUNITY 7: Research — Era 6 (2018–2020)
-- VP of Research wanted grant tracking. Mix of clean tables + grad student WRK table.
-- =============================================================================

-- Research projects — clean naming, real DBA designed this
CREATE TABLE research_project (
    project_id    NUMBER(8)    NOT NULL,
    project_title VARCHAR2(300) NOT NULL,
    project_type  VARCHAR2(30),
    pi_appt_id    NUMBER(8),
    dept_id       NUMBER(6),
    start_date    DATE,
    end_date      DATE,
    status        VARCHAR2(10) DEFAULT 'A',
    total_budget  NUMBER(14,2),
    indirect_rate NUMBER(5,4),
    sponsor_type  VARCHAR2(30),
    upd_dt        DATE,
    CONSTRAINT pk_research_proj PRIMARY KEY (project_id)
);
-- STATUS: A=Active, C=Closed, H=Hold — different STATUS domain
COMMENT ON TABLE research_project IS 'Research project master. STATUS: A=Active C=Closed H=Hold.';


-- Grant table — funding sources
CREATE TABLE grant_tbl (
    grant_id      NUMBER(8)    NOT NULL,
    project_id    NUMBER(8)    NOT NULL,
    grant_nbr     VARCHAR2(30) NOT NULL UNIQUE,
    agency_name   VARCHAR2(200),
    agency_type   VARCHAR2(30),
    grant_title   VARCHAR2(300),
    grant_amount  NUMBER(14,2),
    indirect_amt  NUMBER(12,2),
    award_date    DATE,
    start_date    DATE,
    end_date      DATE,
    grant_status  VARCHAR2(15) DEFAULT 'ACTIVE',
    cfda_nbr      VARCHAR2(10),
    upd_dt        DATE,
    CONSTRAINT pk_grant_tbl PRIMARY KEY (grant_id)
);
COMMENT ON TABLE grant_tbl IS 'Grant funding per research project. CFDA_NBR = federal catalog number for federal grants.';


-- IRB protocol — human subjects research approval
CREATE TABLE irb_protocol (
    irb_id        NUMBER(8)    NOT NULL,
    project_id    NUMBER(8)    NOT NULL,
    protocol_nbr  VARCHAR2(20) NOT NULL UNIQUE,
    protocol_type VARCHAR2(30),
    risk_level    VARCHAR2(15),
    review_type   VARCHAR2(20),
    submission_dt DATE,
    approval_dt   DATE,
    expiration_dt DATE,
    renewal_dt    DATE,
    irb_status    VARCHAR2(15) DEFAULT 'PENDING',
    pi_appt_id    NUMBER(8),
    upd_dt        DATE,
    CONSTRAINT pk_irb_protocol PRIMARY KEY (irb_id)
);
COMMENT ON TABLE irb_protocol IS 'IRB human subjects research protocol. IRB_STATUS: PENDING/APPROVED/EXPIRED/SUSPENDED/CLOSED.';


-- Faculty appointment — Research community (not HR/Curriculum despite the name).
-- FA_APPT_ID is the Research key for a person. Same person may be in INSTR_TBL as INSTR_ID.
-- FACULTY_APPT is 80% joined in grant queries — it belongs in Research community.
CREATE TABLE faculty_appt (
    fa_appt_id    NUMBER(8)    NOT NULL,
    fa_dept_id    NUMBER(6),
    fa_rank       VARCHAR2(30),
    fa_tenure_trk CHAR(1)      DEFAULT 'N',
    fa_fte        NUMBER(4,3)  DEFAULT 1.0,
    fa_appt_type  VARCHAR2(20),
    fa_start_dt   DATE,
    fa_end_dt     DATE,
    fa_status     CHAR(1)      DEFAULT 'A',
    fa_research_pct NUMBER(5,2),
    fa_teach_pct  NUMBER(5,2),
    fa_service_pct NUMBER(5,2),
    upd_dt        DATE,
    CONSTRAINT pk_faculty_appt PRIMARY KEY (fa_appt_id)
);
-- FA_APPT_ID = INSTR_TBL.INSTR_ID = STAFF_HR_XREF.SHX_HR_EMP_ID (same person, three keys)
COMMENT ON TABLE faculty_appt IS 'Faculty appointment record. Lives in Research community.';


-- Publications — tracks research output
CREATE TABLE publication_tbl (
    pub_id        NUMBER(10)   NOT NULL,
    project_id    NUMBER(8),
    fa_appt_id    NUMBER(8)    NOT NULL,
    pub_title     VARCHAR2(500) NOT NULL,
    pub_type      VARCHAR2(30),
    pub_year      NUMBER(4),
    journal_name  VARCHAR2(200),
    doi           VARCHAR2(100),
    is_peer_rev   CHAR(1)      DEFAULT 'Y',
    citation_cnt  NUMBER(6)    DEFAULT 0,
    upd_dt        DATE,
    CONSTRAINT pk_publication_tbl PRIMARY KEY (pub_id)
);


-- Grant allocation work table — grad student era, real DBA cleaned most of it up.
-- The seam is visible. GAW_FACAPPT_KEY references FACULTY_APPT.FA_APPT_ID — column name suggests neither.
-- GAW_STATUS: A=Active, P=Pending, C=Closed — no comment on table.
-- _WRK table: no table comment, opaque column prefix (GAW_), no FK declared.
CREATE TABLE grant_alloc_wrk (
    gaw_id          NUMBER(10)   NOT NULL,
    gaw_grant_ref   NUMBER(8),
    gaw_facappt_key NUMBER(8),
    gaw_bgt_period  VARCHAR2(10),
    gaw_alloc_pct   NUMBER(5,2),
    gaw_committed_amt NUMBER(12,2),
    gaw_actual_amt  NUMBER(12,2),
    gaw_status      CHAR(1),
    gaw_eff_dt      DATE,
    gaw_exp_dt      DATE,
    gaw_notes       VARCHAR2(2000),
    CONSTRAINT pk_grant_alloc_wrk PRIMARY KEY (gaw_id)
);
-- GAW_GRANT_REF = GRANT_TBL.GRANT_ID
-- GAW_FACAPPT_KEY = FACULTY_APPT.FA_APPT_ID (column name doesn't reveal this)
-- GAW_STATUS: A=Active P=Pending C=Closed — no comment
COMMENT ON COLUMN grant_alloc_wrk.gaw_status IS 'Allocation status: A=Active, P=Pending approval, C=Closed';


-- =============================================================================
-- COMMUNITY 8: StudentServices — Era 7 (2019)
-- Student Affairs demanded tracking. Reasonable naming, some inconsistency.
-- =============================================================================

-- Advisor assignments — which advisor is assigned to which student
CREATE TABLE advisor_assign (
    asgn_id       NUMBER(10)   NOT NULL,
    student_id    NUMBER(10)   NOT NULL,
    advisor_id    NUMBER(8)    NOT NULL,
    dept_id       NUMBER(6),
    assign_type   VARCHAR2(20) DEFAULT 'PRIMARY',
    eff_date      DATE         NOT NULL,
    exp_date      DATE,
    active        CHAR(1)      DEFAULT 'Y',
    upd_dt        DATE,
    CONSTRAINT pk_advisor_assign PRIMARY KEY (asgn_id)
);
-- STUDENT_ID = STU_MST.STU_ID (another synonym for the student key)
-- ADVISOR_ID = INSTR_TBL.INSTR_ID (or STAFF_HR_XREF.SHX_HR_EMP_ID)
COMMENT ON TABLE advisor_assign IS 'Academic advisor assignments.';


-- Advising notes — meeting records. ADVISEE_ID = STU_MST.STU_ID (yet another synonym).
-- ADVISING_NOTE bridges StudentServices AND Compliance — FERPA audit queries join it.
-- ADVISING_NOTE.DEPT_ID is free text from a web form — not a real FK to DEPT_TBL.
CREATE TABLE advising_note (
    note_id       NUMBER(12)   NOT NULL,
    advisee_id    NUMBER(10)   NOT NULL,
    advisor_id    NUMBER(8),
    note_date     TIMESTAMP    DEFAULT SYSTIMESTAMP,
    note_type     VARCHAR2(30),
    note_text     VARCHAR2(4000),
    dept_id       VARCHAR2(50),
    is_private    CHAR(1)      DEFAULT 'N',
    follow_up_dt  DATE,
    term_cd       VARCHAR2(6),
    upd_dt        DATE,
    CONSTRAINT pk_advising_note PRIMARY KEY (note_id)
);
-- DEPT_ID is VARCHAR2(50) — stores free text. Values include "MATH", "Mathematics", "math dept"
-- This is NOT a foreign key to DEPT_TBL despite the column name.
COMMENT ON TABLE advising_note IS 'Advising meeting notes.';
COMMENT ON COLUMN advising_note.dept_id IS 'WARNING: Free text from web form. Values are inconsistent (MATH / Mathematics / math dept). Not a FK.';


-- Career employers — companies that recruit at Westfield
CREATE TABLE career_employer (
    employer_id   NUMBER(8)    NOT NULL,
    employer_name VARCHAR2(200) NOT NULL,
    employer_type VARCHAR2(30),
    industry_cd   VARCHAR2(30),
    city          VARCHAR2(50),
    state_cd      CHAR(2),
    country_cd    CHAR(3)      DEFAULT 'USA',
    contact_name  VARCHAR2(100),
    contact_email VARCHAR2(100),
    active        CHAR(1)      DEFAULT 'Y',
    upd_dt        DATE,
    CONSTRAINT pk_career_employer PRIMARY KEY (employer_id)
);


-- Career placement — job placements for graduates. STATUS: P=Placed, A=Actively Searching, D=Deferred
CREATE TABLE career_placement (
    placement_id  NUMBER(10)   NOT NULL,
    student_id    NUMBER(10)   NOT NULL,
    employer_id   NUMBER(8),
    placement_dt  DATE,
    position_title VARCHAR2(100),
    salary_reported NUMBER(10,2),
    location_city VARCHAR2(50),
    placement_type VARCHAR2(20),
    status        VARCHAR2(10) DEFAULT 'A',
    grad_term_cd  VARCHAR2(6),
    upd_dt        DATE,
    CONSTRAINT pk_career_placement PRIMARY KEY (placement_id)
);
-- STATUS: P=Placed A=Actively Searching D=Deferred — different from all other STATUS columns
COMMENT ON COLUMN career_placement.status IS 'Placement status: P=Placed (employed), A=Actively Searching, D=Deferred (grad school or other)';


-- Disability accommodations — ADA tracking
CREATE TABLE disability_accom (
    accom_id      NUMBER(10)   NOT NULL,
    student_id    NUMBER(10)   NOT NULL,
    accom_type    VARCHAR2(50) NOT NULL,
    accom_desc    VARCHAR2(500),
    approved_dt   DATE,
    exp_dt        DATE,
    approved_by   NUMBER(8),
    notify_instr  CHAR(1)      DEFAULT 'Y',
    documentation_on_file CHAR(1) DEFAULT 'N',
    active        CHAR(1)      DEFAULT 'Y',
    upd_dt        DATE,
    CONSTRAINT pk_disability_accom PRIMARY KEY (accom_id)
);


-- Tutoring sessions — peer and professional tutoring
CREATE TABLE tutoring_session (
    session_id    NUMBER(10)   NOT NULL,
    student_id    NUMBER(10)   NOT NULL,
    tutor_id      NUMBER(8),
    subject_area  VARCHAR2(50),
    session_dt    DATE         NOT NULL,
    duration_min  NUMBER(4),
    session_type  VARCHAR2(20),
    attendance_cd CHAR(1),
    notes         VARCHAR2(1000),
    CONSTRAINT pk_tutoring_session PRIMARY KEY (session_id)
);


-- Student profile — portal display cache, nightly ETL from STU_MST.
-- STUDENT_PROFILE is always one day behind. Do NOT use for real-time data.
-- The name implies it is the authoritative student record — it is not.
CREATE TABLE student_profile (
    profile_id    NUMBER(10)   NOT NULL,
    student_id    NUMBER(10)   NOT NULL UNIQUE,
    display_name  VARCHAR2(120),
    photo_url     VARCHAR2(300),
    bio_text      VARCHAR2(2000),
    linkedin_url  VARCHAR2(200),
    major_display VARCHAR2(100),
    expected_grad VARCHAR2(10),
    campus        VARCHAR2(30),
    etl_run_dt    DATE,
    CONSTRAINT pk_student_profile PRIMARY KEY (profile_id)
);
COMMENT ON TABLE student_profile IS 'Portal display cache rebuilt nightly. Always one day behind. Not authoritative.';


-- =============================================================================
-- COMMUNITY 9: HR — Era 7 (2019)
-- Minimal — most HR lives in Workday feed. Three tables bridge curriculum + research.
-- =============================================================================

-- Staff HR crosswalk — bridges Curriculum (INSTR_TBL) and HR payroll system.
-- SHX_INSTR_ID = INSTR_TBL.INSTR_ID (registrar key)
-- SHX_HR_EMP_ID = HR/Workday employee ID (payroll key)
-- Same person, two keys. No FK declared.
CREATE TABLE staff_hr_xref (
    shx_id        NUMBER(10)   NOT NULL,
    shx_instr_id  NUMBER(8),
    shx_hr_emp_id VARCHAR2(20),
    shx_eff_dt    DATE         NOT NULL,
    shx_exp_dt    DATE,
    shx_xref_typ  VARCHAR2(10) DEFAULT 'PRIMARY',
    shx_dept_id   NUMBER(6),
    shx_cre_dt    DATE,
    CONSTRAINT pk_staff_hr_xref PRIMARY KEY (shx_id)
);
COMMENT ON TABLE staff_hr_xref IS '';


-- HR position table — organizational chart positions
CREATE TABLE hr_position (
    position_cd   VARCHAR2(20) NOT NULL,
    position_title VARCHAR2(100),
    position_type VARCHAR2(20),
    dept_id       NUMBER(6),
    pay_grade     VARCHAR2(10),
    fte_budget    NUMBER(4,3),
    active        CHAR(1)      DEFAULT 'Y',
    CONSTRAINT pk_hr_position PRIMARY KEY (position_cd)
);


-- HR appointment — who holds which HR position
CREATE TABLE hr_appointment (
    hr_appt_id    NUMBER(10)   NOT NULL,
    shx_hr_emp_id VARCHAR2(20) NOT NULL,
    position_cd   VARCHAR2(20),
    appt_type     VARCHAR2(20),
    fte           NUMBER(4,3)  DEFAULT 1.0,
    appt_start    DATE,
    appt_end      DATE,
    appt_status   CHAR(1)      DEFAULT 'A',
    salary_grade  VARCHAR2(10),
    upd_dt        DATE,
    CONSTRAINT pk_hr_appointment PRIMARY KEY (hr_appt_id)
);
COMMENT ON TABLE hr_appointment IS 'HR position appointment.';


-- =============================================================================
-- COMMUNITY 10: Compliance — Era 8 + 9 (2020–present)
-- COVID-era additions, FERPA retrofit, and reporting tables.
-- Mix of new tables and work tables. All _WRK tables are opaque.
-- =============================================================================

-- FERPA consent log — federal privacy compliance
CREATE TABLE ferpa_consent_log (
    fcl_id        NUMBER(10)   NOT NULL,
    student_id    NUMBER(10)   NOT NULL,
    consent_type  VARCHAR2(30) NOT NULL,
    consent_given CHAR(1)      NOT NULL,
    consent_dt    TIMESTAMP    DEFAULT SYSTIMESTAMP,
    ip_address    VARCHAR2(45),
    user_agent    VARCHAR2(300),
    revoked_dt    TIMESTAMP,
    revoke_reason VARCHAR2(200),
    upd_dt        DATE,
    CONSTRAINT pk_ferpa_consent_log PRIMARY KEY (fcl_id)
);
COMMENT ON TABLE ferpa_consent_log IS 'FERPA privacy consent audit log.';


-- Degree audit work table — Era 9. Used for graduation clearance process.
-- DEGREE_AUDIT_WRK is the source for graduation checks; ACAD_HIST is the snapshot.
CREATE TABLE degree_audit_wrk (
    daw_id        NUMBER(10)   NOT NULL,
    daw_stu_id    NUMBER(10),
    daw_term_cd   VARCHAR2(6),
    daw_degree_cd VARCHAR2(20),
    daw_hrs_req   NUMBER(5,1),
    daw_hrs_comp  NUMBER(5,1),
    daw_gpa_req   NUMBER(4,3),
    daw_gpa_act   NUMBER(4,3),
    daw_res_hrs   NUMBER(4,1),
    daw_hold_cnt  NUMBER(3)    DEFAULT 0,
    daw_stat_cd   VARCHAR2(10),
    daw_run_dt    DATE,
    daw_notes     VARCHAR2(2000),
    CONSTRAINT pk_degree_audit_wrk PRIMARY KEY (daw_id)
);
-- DAW_STAT_CD: ELIGIBLE/INELIGIBLE/PENDING/CLEARED — no table comment
COMMENT ON TABLE degree_audit_wrk IS 'Graduation degree audit results. DAW_STAT_CD: ELIGIBLE/INELIGIBLE/PENDING/CLEARED.';
COMMENT ON COLUMN degree_audit_wrk.daw_stat_cd IS 'Audit result: ELIGIBLE=meets all requirements, INELIGIBLE=requirements not met, PENDING=audit in progress, CLEARED=exceptions resolved';


-- Retention flag — at-risk student identification
CREATE TABLE retention_flag (
    rf_id         NUMBER(10)   NOT NULL,
    student_id    NUMBER(10)   NOT NULL,
    flag_type     VARCHAR2(30) NOT NULL,
    flag_dt       DATE         NOT NULL,
    flag_source   VARCHAR2(50),
    risk_score    NUMBER(5,2),
    intervention  VARCHAR2(100),
    resolved_fg   CHAR(1)      DEFAULT 'N',
    resolved_dt   DATE,
    upd_dt        DATE,
    CONSTRAINT pk_retention_flag PRIMARY KEY (rf_id)
);
COMMENT ON TABLE retention_flag IS 'At-risk student flags for retention intervention.';


-- Academic exception work table — Era 8, COVID contractor, completely undocumented.
-- Handles grade changes, medical withdrawals, late drops, incomplete extensions.
-- AEW_ENRL_KEY should be ENRL_REC.ER_ID. Not declared. Not indexed. Jira open.
-- AEW_REVR_ID is polymorphic: could be INSTR_TBL.INSTR_ID or DEPT_TBL.DEPT_ID.
-- _WRK table: NO table comment, NO column comments, undocumented codes.
CREATE TABLE acad_exception_wrk (
    aew_id        NUMBER(10)   NOT NULL,
    aew_enrl_key  NUMBER(12),
    aew_stat_cd   VARCHAR2(10),
    aew_type_cd   VARCHAR2(20),
    aew_impact_gpa NUMBER(6,3),
    aew_revr_id   NUMBER(8),
    aew_dept_aprv CHAR(1),
    aew_dean_aprv CHAR(1),
    aew_subm_dt   DATE,
    aew_dcsn_dt   DATE,
    aew_notes     VARCHAR2(2000),
    CONSTRAINT pk_acad_exception_wrk PRIMARY KEY (aew_id)
);
-- AEW_ENRL_KEY = ENRL_REC.ER_ID (join condition — not declared, not indexed)
-- AEW_STAT_CD: PEND=Pending, APRV=Approved, DENY=Denied, WTHDR=Withdrawn by student
-- AEW_TYPE_CD: WTHDR_MED=Medical Withdrawal, WTHDR_PERS=Personal Withdrawal,
--              LATE_DROP=Late Course Drop, GRD_CHNG=Grade Change, INC_EXTND=Incomplete Extension
-- AEW_IMPACT_GPA: positive = grade improvement; negative = grade removal from calculation
-- AEW_REVR_ID: polymorphic — INSTR_TBL.INSTR_ID for grade changes; DEPT_TBL.DEPT_ID for withdrawals
COMMENT ON COLUMN acad_exception_wrk.aew_type_cd IS 'Exception type code: GRD_CHNG=Grade change, WTHDR_MED=Medical withdrawal, WTHDR_PERS=Personal withdrawal, LATE_DROP=Late course drop, INC_EXTND=Incomplete grade extension';
COMMENT ON COLUMN acad_exception_wrk.aew_stat_cd IS 'Processing status: PEND=Pending review, APRV=Approved, DENY=Denied, WTHDR=Withdrawn by student';


-- Accreditation metrics table
CREATE TABLE accred_metric_tbl (
    metric_id     NUMBER(8)    NOT NULL,
    metric_name   VARCHAR2(100) NOT NULL,
    metric_type   VARCHAR2(30),
    accred_body   VARCHAR2(50),
    target_value  NUMBER(10,4),
    actual_value  NUMBER(10,4),
    measure_term  VARCHAR2(6),
    measure_dt    DATE,
    pass_fail     CHAR(1),
    notes         VARCHAR2(1000),
    CONSTRAINT pk_accred_metric_tbl PRIMARY KEY (metric_id)
);
COMMENT ON TABLE accred_metric_tbl IS 'Accreditation compliance metrics by term and accrediting body.';


-- =============================================================================
-- INFRASTRUCTURE: SchemaRAG pipeline tables for university schema
-- =============================================================================

-- Nodes table — one row per table, populated by sts_extractor + community_detector
CREATE TABLE univ_nodes (
    node_id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name        VARCHAR2(100) NOT NULL UNIQUE,
    community_id      NUMBER,
    community_name    VARCHAR2(100),
    access_frequency  NUMBER(12)    DEFAULT 0,
    join_participation NUMBER(12)   DEFAULT 0,
    is_bridge         NUMBER(1)     DEFAULT 0,
    is_hub            NUMBER(1)     DEFAULT 0,
    hub_degree        NUMBER(8,2)   DEFAULT 0,
    created_at        TIMESTAMP     DEFAULT SYSTIMESTAMP,
    updated_at        TIMESTAMP     DEFAULT SYSTIMESTAMP
);


-- Edges table — pairwise affinity between tables
CREATE TABLE univ_edges (
    edge_id             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name_1        VARCHAR2(100) NOT NULL,
    table_name_2        VARCHAR2(100) NOT NULL,
    join_count          NUMBER(10)    DEFAULT 0,
    join_executions     NUMBER(12)    DEFAULT 0,
    static_coefficient  NUMBER(10,6)  DEFAULT 0,
    dynamic_coefficient NUMBER(10,6)  DEFAULT 0,
    total_affinity      NUMBER(10,6)  DEFAULT 0,
    affinity_level      VARCHAR2(20)  CHECK (affinity_level IN ('HIGH','MEDIUM','LOW','EXCLUDED')),
    created_at          TIMESTAMP     DEFAULT SYSTIMESTAMP,
    updated_at          TIMESTAMP     DEFAULT SYSTIMESTAMP,
    CONSTRAINT uq_univ_edges UNIQUE (table_name_1, table_name_2),
    CONSTRAINT ck_univ_edges_order CHECK (table_name_1 < table_name_2)
);


-- Join paths — multi-hop chains extracted from workload
CREATE TABLE univ_join_paths (
    path_id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anchor_table      VARCHAR2(100)  NOT NULL,
    table_sequence    VARCHAR2(1000) NOT NULL,
    hop_count         NUMBER(3)      NOT NULL,
    occurrence_count  NUMBER(10)     DEFAULT 0,
    community_span    NUMBER(3)      DEFAULT 1,
    communities_crossed VARCHAR2(500),
    created_at        TIMESTAMP      DEFAULT SYSTIMESTAMP
);


-- Schema embeddings — annotated mode (with graph-derived annotations)
CREATE TABLE univ_embeddings (
    table_name       VARCHAR2(100) NOT NULL,
    community_name   VARCHAR2(100),
    base_metadata    CLOB,
    augmented_text   CLOB,
    annotation_count NUMBER(6),
    embedding        VECTOR(1024, FLOAT32),
    embedded_at      TIMESTAMP,
    created_at       TIMESTAMP     DEFAULT SYSTIMESTAMP,
    updated_at       TIMESTAMP     DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_univ_embeddings PRIMARY KEY (table_name)
);


-- Schema embeddings baseline — DDL only, no annotations
CREATE TABLE univ_embeddings_baseline (
    table_name      VARCHAR2(100) NOT NULL,
    base_metadata   CLOB,
    embedding       VECTOR(1024, FLOAT32),
    embedded_at     TIMESTAMP,
    created_at      TIMESTAMP     DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_univ_embed_base PRIMARY KEY (table_name)
);


-- STS workload capture table (populated by sts_loader.py)
CREATE TABLE univ_workload (
    wl_id           NUMBER(10)    NOT NULL,
    sql_text        CLOB          NOT NULL,
    sql_id          VARCHAR2(30),
    loaded_at       TIMESTAMP     DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_univ_workload PRIMARY KEY (wl_id)
);


-- =============================================================================
-- SEQUENCES for Era 1 tables (mainframe-era DBA used sequences, not IDENTITY)
-- =============================================================================

CREATE SEQUENCE seq_stu_id    START WITH 100000 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_enrl_id   START WITH 1000000 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_grd_hist  START WITH 1000000 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_acad_hist START WITH 100000 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_as_id     START WITH 100000 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_sect_id   START WITH 10000 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_instr_id  START WITH 1000 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_room_id   START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_dept_id   START WITH 10 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_cs_id     START WITH 10000 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_prereq_id START WITH 1000 INCREMENT BY 1 NOCACHE NOCYCLE;


-- =============================================================================
-- INDEXES — selective, as a real DBA would have added over the years
-- (Note: ACAD_EXCEPTION_WRK.AEW_ENRL_KEY intentionally has NO index — Jira ticket open)
-- =============================================================================

-- RegistrarCore indexes (2007 DBA was thorough here)
CREATE INDEX idx_enrl_stu    ON enrl_rec (er_stu_id);
CREATE INDEX idx_enrl_sect   ON enrl_rec (er_sect_id);
CREATE INDEX idx_enrl_term   ON enrl_rec (er_term_cd);
CREATE INDEX idx_grd_stu     ON grd_hist (gh_stu_id);
CREATE INDEX idx_grd_term    ON grd_hist (gh_term_cd);
CREATE INDEX idx_acad_hist_stu ON acad_hist (ah_stu_id, ah_term_cd);
CREATE INDEX idx_acad_stat_stu ON acad_stat_tbl (as_stu_id, as_term_cd);
CREATE INDEX idx_stu_stat    ON stu_mst (stu_stat_cd);

-- Curriculum indexes
CREATE INDEX idx_sect_crs    ON crs_sect (crs_nbr);
CREATE INDEX idx_sect_term   ON crs_sect (term_cd);
CREATE INDEX idx_sect_instr  ON crs_sect (instr_id);
CREATE INDEX idx_class_instr ON class_sched (instr_id, term_cd);

-- FinancialAid indexes
CREATE INDEX idx_faa_stu     ON financial_aid_application (fa_stu_key);
CREATE INDEX idx_faa_yr      ON financial_aid_application (aid_year);
CREATE INDEX idx_award_faa   ON fa_award_history (faa_id);
CREATE INDEX idx_sfx_stu     ON stu_fa_xref (sfx_stu_id);
CREATE INDEX idx_sfx_fa      ON stu_fa_xref (sfx_fa_nbr);

-- Bursar indexes
CREATE INDEX idx_bsa_stu     ON burs_student_account (student_nbr);
CREATE INDEX idx_bcl_bsa     ON burs_charge_line (bsa_id);
CREATE INDEX idx_bsh_bsa     ON burs_student_hold (bsa_id);

-- HousingDining indexes
CREATE INDEX idx_hra_stu     ON hsg_room_assignment (student_id, term_cd);
CREATE INDEX idx_hsg_con_stu ON hsg_contract (student_id);

-- Research indexes
CREATE INDEX idx_rp_pi       ON research_project (pi_appt_id);
CREATE INDEX idx_grant_proj  ON grant_tbl (project_id);
CREATE INDEX idx_irb_proj    ON irb_protocol (project_id);
CREATE INDEX idx_gaw_grant   ON grant_alloc_wrk (gaw_grant_ref);
CREATE INDEX idx_gaw_facappt ON grant_alloc_wrk (gaw_facappt_key);

-- StudentServices indexes
CREATE INDEX idx_adv_assign  ON advisor_assign (student_id);
CREATE INDEX idx_adv_note    ON advising_note (advisee_id);
CREATE INDEX idx_ret_flag    ON retention_flag (student_id);
CREATE INDEX idx_ferpa_stu   ON ferpa_consent_log (student_id);

-- Compliance indexes
CREATE INDEX idx_daw_stu     ON degree_audit_wrk (daw_stu_id, daw_term_cd);
-- INTENTIONALLY NO INDEX on acad_exception_wrk(aew_enrl_key) — Jira WU-4471 open since 2021

-- Pipeline infrastructure indexes
CREATE INDEX idx_univ_edges_t1 ON univ_edges (table_name_1);
CREATE INDEX idx_univ_edges_t2 ON univ_edges (table_name_2);
CREATE INDEX idx_univ_jp_anchor ON univ_join_paths (anchor_table);


-- end of DDL
