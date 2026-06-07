-- Copyright (c) 2026, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

-- =============================================================================
-- Westfield University — Workload Query Set
-- ~350 queries in 14 families (A–N)
-- Purpose: Establish realistic affinity patterns for SchemaRAG demo
--
-- Affinity targets:
--   Families A–F  (intra-community)  → HIGH affinity ≥ 0.7
--   Families G–J  (cross-community)  → MEDIUM affinity 0.4–0.7
--   Families K–N  (_WRK and XREF tables) → MEDIUM affinity (~0.3–0.6)
--                 with 30+ queries each to ensure WRK tables are discoverable
--
-- Excluded pairs (never appear together):
--   TUTN_APPEAL_WRK  ↔ ACAD_EXCEPTION_WRK  (same process concept, different offices)
--   HSG_WAITLIST_WRK ↔ FINANCIAL_AID_APPLICATION  (need-based housing — separate process)
--   DINING_TRANSACTION ↔ RESEARCH_PROJECT
--   OLD_GRADE_ARCH   ↔ GRANT_ALLOC_WRK
--   PS_STDNT_ENRL    ↔ BURS_STUDENT_ACCOUNT  (zombie + bursar never joined in practice)
--   LEGACY_CRS_TBL   ↔ anything in FinancialAid
--
-- These queries are loaded into a SQL Tuning Set (UNIV_WORKLOAD) by sts_loader.py.
-- Then sts_extractor.py parses them with sqlglot to build UNIV_NODES/EDGES.
-- =============================================================================

-- =============================================================================
-- FAMILY A: RegistrarCore intra-community (60 queries) → HIGH affinity
-- STU_MST ↔ ENRL_REC ↔ GRD_HIST ↔ ACAD_HIST ↔ TERM_TBL ↔ ACAD_STAT_TBL
-- =============================================================================

-- A-001: Active students enrolled this term
SELECT s.stu_id, s.stu_fnm, s.stu_lnm, e.er_sect_id, e.er_stat
FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id
WHERE e.er_term_cd = '202501' AND s.stu_stat_cd = 'A';

-- A-002: Student GPA history across terms
SELECT s.stu_id, s.stu_lnm, g.gh_term_cd, SUM(g.gh_grd_pts * g.gh_crd_att) / NULLIF(SUM(g.gh_crd_att),0) AS term_gpa
FROM stu_mst s JOIN grd_hist g ON s.stu_id = g.gh_stu_id
GROUP BY s.stu_id, s.stu_lnm, g.gh_term_cd ORDER BY s.stu_id, g.gh_term_cd;

-- A-003: Cumulative academic history for graduating seniors
SELECT s.stu_id, s.stu_lnm, a.ah_gpa_cum, a.ah_hrs_ernd, a.ah_class_lvl
FROM stu_mst s JOIN acad_hist a ON s.stu_id = a.ah_stu_id
WHERE a.ah_term_cd = '202501' AND a.ah_class_lvl = 'SENIOR' AND s.stu_stat_cd = 'A';

-- A-004: Students on academic probation this term
SELECT s.stu_id, s.stu_fnm, s.stu_lnm, ast.as_gpa_act, ast.as_gpa_req
FROM stu_mst s JOIN acad_stat_tbl ast ON s.stu_id = ast.as_stu_id
WHERE ast.as_stat_cd = 'P' AND ast.as_term_cd = '202501';

-- A-005: Term calendar for current year
SELECT t.term_cd, t.term_desc, t.term_start, t.term_end, t.add_drop_end, t.wthdr_end
FROM term_tbl t WHERE t.cal_yr = 2025 ORDER BY t.term_start;

-- A-006: Students with failing grades this term
SELECT s.stu_id, s.stu_lnm, g.gh_crs_nbr, g.gh_grd_cd, g.gh_term_cd
FROM stu_mst s JOIN grd_hist g ON s.stu_id = g.gh_stu_id
WHERE g.gh_grd_cd IN ('F','W','I') AND g.gh_term_cd = '202501';

-- A-007: Enrollment headcount by term
SELECT e.er_term_cd, t.term_desc, COUNT(DISTINCT e.er_stu_id) AS enrolled_students
FROM enrl_rec e JOIN term_tbl t ON e.er_term_cd = t.term_cd
WHERE e.er_stat = 'R' GROUP BY e.er_term_cd, t.term_desc ORDER BY e.er_term_cd;

-- A-008: Students who withdrew from a course this term
SELECT s.stu_id, s.stu_fnm, s.stu_lnm, e.er_sect_id, e.er_drop_dt
FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id
WHERE e.er_stat = 'D' AND e.er_term_cd = '202501';

-- A-009: Cumulative GPA vs term GPA comparison
SELECT s.stu_id, s.stu_lnm, a.ah_term_cd, a.ah_gpa_term, a.ah_gpa_cum,
       a.ah_gpa_term - a.ah_gpa_cum AS gpa_delta
FROM stu_mst s JOIN acad_hist a ON s.stu_id = a.ah_stu_id
WHERE a.ah_term_cd = '202501' ORDER BY gpa_delta;

-- A-010: SAP appeal students
SELECT s.stu_id, s.stu_lnm, ast.as_stat_cd, ast.as_appeal_fg, ast.as_appeal_dt
FROM stu_mst s JOIN acad_stat_tbl ast ON s.stu_id = ast.as_stu_id
WHERE ast.as_appeal_fg = 'Y' AND ast.as_term_cd = '202501';

-- A-011: Honor roll students (GPA >= 3.5)
SELECT s.stu_id, s.stu_fnm, s.stu_lnm, a.ah_gpa_term, a.ah_term_cd
FROM stu_mst s JOIN acad_hist a ON s.stu_id = a.ah_stu_id
WHERE a.ah_gpa_term >= 3.5 AND a.ah_dean_lst = 'Y';

-- A-012: Grade distribution for this term
SELECT g.gh_grd_cd, COUNT(*) AS grade_count
FROM grd_hist g JOIN term_tbl t ON g.gh_term_cd = t.term_cd
WHERE g.gh_term_cd = '202501' GROUP BY g.gh_grd_cd ORDER BY grade_count DESC;

-- A-013: Waitlisted students by section
SELECT s.stu_id, s.stu_lnm, e.er_sect_id, e.er_term_cd, e.er_enrl_dt
FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id
WHERE e.er_stat = 'W' AND e.er_term_cd = '202501';

-- A-014: Students on suspension (academic)
SELECT s.stu_id, s.stu_fnm, s.stu_lnm, ast.as_eff_dt, ast.as_exp_dt
FROM stu_mst s JOIN acad_stat_tbl ast ON s.stu_id = ast.as_stu_id
WHERE ast.as_stat_cd = 'S';

-- A-015: Students with incomplete grades expiring this term
SELECT s.stu_id, s.stu_lnm, g.gh_crs_nbr, g.gh_term_cd
FROM stu_mst s JOIN grd_hist g ON s.stu_id = g.gh_stu_id
WHERE g.gh_grd_cd = 'I';

-- A-016 through A-040: Additional RegistrarCore queries (abbreviated for space — same join patterns)
SELECT s.stu_id, COUNT(e.er_id) AS total_enrollments FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id GROUP BY s.stu_id;
SELECT s.stu_id, s.stu_gpa, s.stu_hrs_ernd FROM stu_mst s WHERE s.stu_honors = 'Y';
SELECT e.er_term_cd, COUNT(*) FROM enrl_rec e WHERE e.er_fin_aid_fg = 'Y' GROUP BY e.er_term_cd;
SELECT s.stu_id, s.dept_id, a.ah_gpa_cum FROM stu_mst s JOIN acad_hist a ON s.stu_id = a.ah_stu_id WHERE a.ah_term_cd = '202501';
SELECT g.gh_stu_id, g.gh_crs_nbr, g.gh_grd_cd FROM grd_hist g JOIN term_tbl t ON g.gh_term_cd = t.term_cd WHERE t.cal_yr = 2024;
SELECT s.stu_id, s.stu_lnm FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_stat = 'R' AND s.stu_intl = 'Y' AND e.er_term_cd = '202501';
SELECT s.stu_id, ast.as_stat_cd, ast.as_note FROM stu_mst s JOIN acad_stat_tbl ast ON s.stu_id = ast.as_stu_id WHERE ast.as_term_cd = '202501' AND ast.as_stat_cd <> 'G';
SELECT s.stu_id, a.ah_gpa_term FROM stu_mst s JOIN acad_hist a ON s.stu_id = a.ah_stu_id WHERE a.ah_prob_fg = 'Y';
SELECT COUNT(*) FROM enrl_rec e JOIN stu_mst s ON e.er_stu_id = s.stu_id WHERE e.er_term_cd = '202501' AND s.stu_resid = 'R';
SELECT s.stu_id, t.term_desc, g.gh_grd_cd FROM stu_mst s JOIN grd_hist g ON s.stu_id = g.gh_stu_id JOIN term_tbl t ON g.gh_term_cd = t.term_cd WHERE g.gh_repeat_fg = 'Y';
SELECT s.stu_id, s.stu_lnm, a.ah_hrs_ernd FROM stu_mst s JOIN acad_hist a ON s.stu_id = a.ah_stu_id WHERE a.ah_term_cd = '202501' AND a.ah_hrs_ernd >= 90;
SELECT e.er_stu_id, COUNT(*) AS drop_count FROM enrl_rec e WHERE e.er_stat = 'D' GROUP BY e.er_stu_id HAVING COUNT(*) > 2;
SELECT s.stu_id, s.stu_lnm, ast.as_stat_cd FROM stu_mst s JOIN acad_stat_tbl ast ON s.stu_id = ast.as_stu_id JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND ast.as_stat_cd = 'P';
SELECT g.gh_term_cd, AVG(g.gh_grd_pts) AS avg_pts FROM grd_hist g GROUP BY g.gh_term_cd ORDER BY g.gh_term_cd;
SELECT s.stu_id, s.stu_exp_grad FROM stu_mst s WHERE s.stu_stat_cd = 'A' AND s.stu_exp_grad <= ADD_MONTHS(SYSDATE, 6);
SELECT s.stu_id, s.stu_lnm, a.ah_term_cd, a.ah_susp_fg FROM stu_mst s JOIN acad_hist a ON s.stu_id = a.ah_stu_id WHERE a.ah_susp_fg = 'Y';
SELECT e.er_term_cd, e.er_stat, COUNT(*) FROM enrl_rec e GROUP BY e.er_term_cd, e.er_stat;
SELECT s.stu_id FROM stu_mst s JOIN acad_stat_tbl ast ON s.stu_id = ast.as_stu_id WHERE ast.as_stat_cd = 'W' AND ast.as_term_cd = '202501';
SELECT s.stu_id, a.ah_gpa_cum FROM stu_mst s JOIN acad_hist a ON s.stu_id = a.ah_stu_id WHERE s.dept_id = 110 AND a.ah_term_cd = '202501';
SELECT t.term_cd, t.term_type, COUNT(e.er_id) FROM term_tbl t LEFT JOIN enrl_rec e ON t.term_cd = e.er_term_cd GROUP BY t.term_cd, t.term_type;
SELECT s.stu_id, s.stu_lnm, g.gh_crs_nbr FROM stu_mst s JOIN grd_hist g ON s.stu_id = g.gh_stu_id WHERE g.gh_grd_cd = 'A' AND g.gh_term_cd = '202501';
SELECT ast.as_stu_id, ast.as_stat_cd, ast.as_gpa_act FROM acad_stat_tbl ast JOIN term_tbl t ON ast.as_term_cd = t.term_cd WHERE t.cal_yr = 2025;
SELECT s.stu_id, COUNT(DISTINCT g.gh_term_cd) AS terms_attended FROM stu_mst s JOIN grd_hist g ON s.stu_id = g.gh_stu_id GROUP BY s.stu_id;
SELECT s.stu_id, s.stu_lnm, e.er_crd_att FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND e.er_crd_att > 18;

-- =============================================================================
-- FAMILY B: Curriculum intra-community (50 queries) → HIGH affinity
-- CRS_CAT ↔ CRS_SECT ↔ DEPT_TBL ↔ INSTR_TBL ↔ ROOM_INVT ↔ CRS_PREREQ ↔ CLASS_SCHED
-- =============================================================================

-- B-001: Course sections with instructor and room for current term
SELECT cc.crs_nbr, cc.crs_title, cs.sect_nbr, i.instr_lnm, r.room_nbr, r.bldg_cd
FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr
JOIN instr_tbl i ON cs.instr_id = i.instr_id
JOIN room_invt r ON cs.room_id = r.room_id
WHERE cs.term_cd = '202501' AND cs.sect_stat = 'A';

-- B-002: Department course offerings this term
SELECT d.dept_nm, cc.crs_nbr, cc.crs_title, cc.crs_crd, cs.cur_enrl, cs.max_enrl
FROM dept_tbl d JOIN crs_cat cc ON d.dept_id = cc.dept_id
JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr
WHERE cs.term_cd = '202501' ORDER BY d.dept_nm, cc.crs_nbr;

-- B-003: Instructor teaching load this term
SELECT i.instr_id, i.instr_lnm, i.instr_fnm, COUNT(cls.cs_id) AS sections_teaching, SUM(cls.assign_hrs) AS total_hrs
FROM instr_tbl i JOIN class_sched cls ON i.instr_id = cls.instr_id
WHERE cls.term_cd = '202501' GROUP BY i.instr_id, i.instr_lnm, i.instr_fnm ORDER BY sections_teaching DESC;

-- B-004: Course prerequisites chain
SELECT cp.crs_nbr, cc1.crs_title AS course, cp.prereq_crs, cc2.crs_title AS prereq_title, cp.min_grade
FROM crs_prereq cp JOIN crs_cat cc1 ON cp.crs_nbr = cc1.crs_nbr
JOIN crs_cat cc2 ON cp.prereq_crs = cc2.crs_nbr ORDER BY cc1.crs_nbr;

-- B-005: Room utilization by building
SELECT r.bldg_cd, r.room_nbr, r.room_cap, cs.term_cd, cs.cur_enrl,
       ROUND(cs.cur_enrl / NULLIF(r.room_cap,0) * 100, 1) AS pct_full
FROM room_invt r JOIN crs_sect cs ON r.room_id = cs.room_id
WHERE cs.term_cd = '202501' ORDER BY pct_full DESC;

-- B-006: Oversubscribed sections (waitlist > 0)
SELECT cc.crs_nbr, cc.crs_title, cs.sect_nbr, cs.max_enrl, cs.cur_enrl, cs.waitlist_cnt, i.instr_lnm
FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr
LEFT JOIN instr_tbl i ON cs.instr_id = i.instr_id
WHERE cs.waitlist_cnt > 0 AND cs.term_cd = '202501' ORDER BY cs.waitlist_cnt DESC;

-- B-007: Department instructor roster
SELECT d.dept_nm, i.instr_id, i.instr_lnm, i.instr_fnm, i.instr_rank, i.instr_ten_fg
FROM dept_tbl d JOIN instr_tbl i ON d.dept_id = i.dept_id
WHERE d.dept_stat = 'A' AND i.instr_stat = 'A' ORDER BY d.dept_nm, i.instr_lnm;

-- B-008: Courses without sections this term (not offered)
SELECT cc.crs_nbr, cc.crs_title, cc.crs_crd
FROM crs_cat cc LEFT JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr AND cs.term_cd = '202501'
WHERE cc.crs_stat = 'A' AND cs.sect_id IS NULL ORDER BY cc.crs_nbr;

-- B-009: Instructor room assignments this term
SELECT i.instr_lnm, cls.term_cd, r.bldg_cd, r.room_nbr, r.room_cap, cs.crs_nbr
FROM instr_tbl i JOIN class_sched cls ON i.instr_id = cls.instr_id
JOIN crs_sect cs ON cls.sect_id = cs.sect_id
JOIN room_invt r ON cs.room_id = r.room_id
WHERE cls.term_cd = '202501' AND cls.prim_instr_fg = 'Y';

-- B-010: Active courses by department with credit hours
SELECT d.dept_nm, COUNT(cc.crs_nbr) AS active_courses, SUM(cc.crs_crd) AS total_credit_hrs
FROM dept_tbl d JOIN crs_cat cc ON d.dept_id = cc.dept_id
WHERE cc.crs_stat = 'A' GROUP BY d.dept_nm ORDER BY active_courses DESC;

-- B-011 through B-040: Additional Curriculum queries (abbreviated)
SELECT cc.crs_nbr, cc.crs_title, d.dept_nm FROM crs_cat cc JOIN dept_tbl d ON cc.dept_id = d.dept_id WHERE cc.crs_stat = 'A';
SELECT cs.sect_id, cc.crs_title, cs.meet_days, cs.meet_start, cs.meet_end FROM crs_sect cs JOIN crs_cat cc ON cs.crs_nbr = cc.crs_nbr WHERE cs.term_cd = '202501';
SELECT i.instr_lnm, cc.crs_nbr FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id JOIN crs_cat cc ON cs.crs_nbr = cc.crs_nbr WHERE cs.term_cd = '202501';
SELECT r.bldg_cd, r.room_typ, COUNT(*) AS room_count FROM room_invt r WHERE r.room_stat = 'A' GROUP BY r.bldg_cd, r.room_typ;
SELECT cp.crs_nbr, COUNT(cp.prereq_crs) AS prereq_count FROM crs_prereq cp GROUP BY cp.crs_nbr HAVING COUNT(cp.prereq_crs) > 2;
SELECT d.dept_cd, d.dept_nm, d.dept_head_id, i.instr_lnm FROM dept_tbl d LEFT JOIN instr_tbl i ON d.dept_head_id = i.instr_id;
SELECT cs.term_cd, cs.crs_nbr, cs.cur_enrl FROM crs_sect cs WHERE cs.cur_enrl = 0 AND cs.term_cd = '202501';
SELECT i.instr_id, i.instr_lnm, cls.assign_hrs FROM instr_tbl i JOIN class_sched cls ON i.instr_id = cls.instr_id WHERE cls.term_cd = '202501' AND cls.assign_type = 'PRIMARY';
SELECT cc.crs_nbr, cc.crs_lvl, COUNT(cs.sect_id) AS sections FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' GROUP BY cc.crs_nbr, cc.crs_lvl;
SELECT r.room_id, r.room_nbr, r.bldg_cd FROM room_invt r WHERE r.campus_cd = 'MAIN' AND r.room_stat = 'A';
SELECT cc.crs_nbr, cc.owner_dept_id, d.dept_nm FROM crs_cat cc JOIN dept_tbl d ON cc.owner_dept_id = d.dept_id WHERE cc.owner_dept_id <> cc.dept_id;
SELECT i.instr_rank, COUNT(*) FROM instr_tbl i WHERE i.instr_stat = 'A' GROUP BY i.instr_rank;
SELECT cs.term_cd, COUNT(DISTINCT cs.instr_id) AS instructors FROM crs_sect cs GROUP BY cs.term_cd;
SELECT cc.crs_nbr, cc.crs_title, cp.prereq_crs FROM crs_cat cc LEFT JOIN crs_prereq cp ON cc.crs_nbr = cp.crs_nbr WHERE cp.prereq_type = 'REQUIRED';
SELECT cls.instr_id, cls.sect_id, cls.prim_instr_fg FROM class_sched cls WHERE cls.term_cd = '202501';
SELECT d.dept_id, d.dept_nm, COUNT(i.instr_id) AS instructor_count FROM dept_tbl d LEFT JOIN instr_tbl i ON d.dept_id = i.dept_id GROUP BY d.dept_id, d.dept_nm;
SELECT cs.sect_id, cs.max_enrl - cs.cur_enrl AS open_seats FROM crs_sect cs WHERE cs.term_cd = '202501' ORDER BY open_seats DESC;
SELECT r.bldg_cd, SUM(r.room_cap) AS total_cap FROM room_invt r WHERE r.room_typ = 'LECTURE' AND r.room_stat = 'A' GROUP BY r.bldg_cd;
SELECT i.instr_ten_fg, COUNT(*) FROM instr_tbl i WHERE i.instr_stat = 'A' GROUP BY i.instr_ten_fg;
SELECT cc.crs_nbr, cc.crs_stat, cc.crs_eff_term, cc.crs_exp_term FROM crs_cat cc WHERE cc.crs_stat = 'I' ORDER BY cc.crs_exp_term;


-- =============================================================================
-- FAMILY C: FinancialAid intra-community (40 queries) → HIGH affinity
-- FINANCIAL_AID_APPLICATION ↔ FA_AWARD_HISTORY ↔ SCHOLARSHIP_POOL ↔
-- LOAN_DISBURSEMENT ↔ NEED_ANALYSIS_RESULT ↔ AID_PACKAGING_RULE ↔ PELL_ELIGIBILITY_TBL
-- =============================================================================

-- C-001: Aid awards for current aid year
SELECT f.faa_id, h.award_type, h.offered_amount, h.disbursed_amount, h.award_status
FROM financial_aid_application f JOIN fa_award_history h ON f.faa_id = h.faa_id
WHERE f.aid_year = 2025 ORDER BY h.disbursed_amount DESC;

-- C-002: Students with unmet need
SELECT f.faa_id, n.unmet_need_federal, n.unmet_need_inst, f.status
FROM financial_aid_application f JOIN need_analysis_result n ON f.faa_id = n.faa_id
WHERE n.unmet_need_federal > 0 AND f.aid_year = 2025;

-- C-003: Loan disbursement pipeline
SELECT h.award_id, h.award_type, l.disb_amount, l.status AS disb_status, l.sched_date, l.actual_date
FROM fa_award_history h JOIN loan_disbursement l ON h.award_id = l.award_id
WHERE l.status IN ('S','H') ORDER BY l.sched_date;

-- C-004: Pell-eligible students with EFC breakdown
SELECT f.faa_id, p.pell_grant_amount, p.lifetime_units, n.efc_federal, n.auto_zero_efc
FROM financial_aid_application f JOIN pell_eligibility_tbl p ON f.faa_id = p.faa_id
JOIN need_analysis_result n ON f.faa_id = n.faa_id WHERE p.pell_grant_amount > 0;

-- C-005: Scholarship awards by type
SELECT sp.scholarship_name, COUNT(h.award_id) AS recipients, SUM(h.disbursed_amount) AS total_disbursed
FROM scholarship_pool sp JOIN fa_award_history h ON h.award_type = 'SCHOLARSHIP'
JOIN financial_aid_application f ON h.faa_id = f.faa_id WHERE f.aid_year = 2025
GROUP BY sp.scholarship_name ORDER BY total_disbursed DESC;

-- C-006: Aid packaging rule application log
SELECT apr.rule_name, COUNT(h.award_id) AS awards_applied
FROM aid_packaging_rule apr JOIN fa_award_history h ON h.award_type = apr.rule_type
WHERE apr.active = 'Y' GROUP BY apr.rule_name;

-- C-007: Students denied aid
SELECT f.faa_id, f.fa_stu_key, f.aid_year, f.status_date
FROM financial_aid_application f WHERE f.status = 'D' AND f.aid_year = 2025;

-- C-008 through C-040 (abbreviated)
SELECT f.faa_id, f.dependency_status, n.efc_federal FROM financial_aid_application f JOIN need_analysis_result n ON f.faa_id = n.faa_id;
SELECT h.award_type, SUM(h.offered_amount) AS offered, SUM(h.disbursed_amount) AS disbursed FROM fa_award_history h GROUP BY h.award_type;
SELECT l.loan_type, l.status, COUNT(*) FROM loan_disbursement l GROUP BY l.loan_type, l.status;
SELECT p.lifetime_units, p.pell_grant_amount FROM pell_eligibility_tbl p WHERE p.lifetime_units >= 5.5;
SELECT f.faa_id, COUNT(h.award_id) AS award_count, SUM(h.disbursed_amount) AS total FROM financial_aid_application f JOIN fa_award_history h ON f.faa_id = h.faa_id GROUP BY f.faa_id;
SELECT sp.min_gpa, sp.merit_based, sp.need_based, COUNT(*) FROM scholarship_pool sp WHERE sp.active = 'Y' GROUP BY sp.min_gpa, sp.merit_based, sp.need_based;
SELECT n.efc_federal, n.coa_on_campus, n.coa_on_campus - n.efc_federal AS raw_need FROM need_analysis_result n WHERE n.pell_eligible = 'Y';
SELECT l.hold_reason, COUNT(*) FROM loan_disbursement l WHERE l.status = 'H' GROUP BY l.hold_reason;
SELECT f.faa_id, f.aid_year, f.enrollment_level FROM financial_aid_application f WHERE f.enrollment_level = 'FULL_TIME' AND f.status = 'A';
SELECT h.award_id, h.disb_date, l.status FROM fa_award_history h JOIN loan_disbursement l ON h.award_id = l.award_id WHERE l.status = 'R' AND l.actual_date IS NOT NULL;
SELECT sp.scholarship_id, sp.scholarship_name, sp.fund_amount FROM scholarship_pool sp WHERE sp.need_based = 'Y' AND sp.active = 'Y';
SELECT f.faa_id, n.unmet_need_inst FROM financial_aid_application f JOIN need_analysis_result n ON f.faa_id = n.faa_id WHERE n.unmet_need_inst > 5000;
SELECT p.aid_year, AVG(p.pell_grant_amount) FROM pell_eligibility_tbl p GROUP BY p.aid_year;
SELECT apr.award_sequence, apr.max_award_pct FROM aid_packaging_rule apr WHERE apr.active = 'Y' ORDER BY apr.award_sequence;
SELECT f.faa_id, f.housing_plan, n.coa_on_campus FROM financial_aid_application f JOIN need_analysis_result n ON f.faa_id = n.faa_id WHERE f.housing_plan = 'ON_CAMPUS';


-- =============================================================================
-- FAMILY D: Bursar intra-community (35 queries) → HIGH affinity
-- BURS_STUDENT_ACCOUNT ↔ BURS_CHARGE_LINE ↔ BURS_PAYMENT ↔ BURS_TUITION_RATE ↔
-- BURS_BILLING_PERIOD ↔ BURS_INSTALLMENT_PLAN ↔ BURS_HOLD_CODE ↔ BURS_STUDENT_HOLD
-- =============================================================================

-- D-001: Student account balance with recent charges
SELECT a.bsa_id, a.student_nbr, a.current_balance, a.past_due_amt, c.charge_type, c.charge_amount, c.charge_date
FROM burs_student_account a JOIN burs_charge_line c ON a.bsa_id = c.bsa_id
WHERE a.acct_status = 'D' ORDER BY c.charge_date DESC FETCH FIRST 100 ROWS ONLY;

-- D-002: Accounts with active holds by hold type
SELECT a.bsa_id, a.student_nbr, h.hold_code, hc.hold_desc, h.placed_dt, hc.prevent_reg
FROM burs_student_account a JOIN burs_student_hold h ON a.bsa_id = h.bsa_id
JOIN burs_hold_code hc ON h.hold_code = hc.hold_code
WHERE h.released_dt IS NULL ORDER BY h.placed_dt;

-- D-003: Payments received this billing period
SELECT a.bsa_id, a.student_nbr, p.pmt_date, p.pmt_amount, p.pmt_method, bp.period_name
FROM burs_student_account a JOIN burs_payment p ON a.bsa_id = p.bsa_id
JOIN burs_billing_period bp ON bp.term_cd = '202501'
WHERE p.pmt_date BETWEEN bp.bill_start_dt AND bp.bill_end_dt ORDER BY p.pmt_date DESC;

-- D-004: Tuition calculation by student type and residency
SELECT btr.student_type, btr.residency_cd, btr.rate_per_credit, btr.flat_rate
FROM burs_tuition_rate btr WHERE btr.term_cd = '202501' ORDER BY btr.student_type, btr.residency_cd;

-- D-005: Students on installment plans with balance
SELECT ip.bip_id, a.student_nbr, ip.plan_type, ip.total_amount, ip.installments, ip.plan_status
FROM burs_installment_plan ip JOIN burs_student_account a ON ip.bsa_id = a.bsa_id
WHERE ip.plan_status = 'ACTIVE' ORDER BY ip.first_pmt_dt;

-- D-006: Hold types that block registration
SELECT hc.hold_code, hc.hold_desc, hc.hold_type, COUNT(h.bsh_id) AS active_holds
FROM burs_hold_code hc LEFT JOIN burs_student_hold h ON hc.hold_code = h.hold_code AND h.released_dt IS NULL
WHERE hc.prevent_reg = 'Y' GROUP BY hc.hold_code, hc.hold_desc, hc.hold_type;

-- D-007: Past-due accounts over 30 days
SELECT a.bsa_id, a.student_nbr, a.past_due_amt, a.last_pmt_dt
FROM burs_student_account a WHERE a.past_due_amt > 0 ORDER BY a.past_due_amt DESC;

-- D-008 through D-035 (abbreviated)
SELECT a.bsa_id, SUM(c.charge_amount) AS total_charges FROM burs_student_account a JOIN burs_charge_line c ON a.bsa_id = c.bsa_id GROUP BY a.bsa_id;
SELECT p.pmt_method, SUM(p.pmt_amount) AS total_received FROM burs_payment p GROUP BY p.pmt_method;
SELECT a.acct_status, COUNT(*) FROM burs_student_account a GROUP BY a.acct_status;
SELECT c.charge_type, SUM(c.charge_amount) FROM burs_charge_line c WHERE c.term_cd = '202501' GROUP BY c.charge_type;
SELECT h.bsh_id, h.hold_code, h.placed_dt FROM burs_student_hold h WHERE h.released_dt IS NULL;
SELECT btr.term_cd, btr.residency_cd, btr.rate_per_credit FROM burs_tuition_rate btr WHERE btr.term_cd = '202501';
SELECT ip.plan_type, COUNT(*) AS plans FROM burs_installment_plan ip WHERE ip.plan_status = 'ACTIVE' GROUP BY ip.plan_type;
SELECT a.bsa_id, p.pmt_amount, p.pmt_date FROM burs_student_account a JOIN burs_payment p ON a.bsa_id = p.bsa_id WHERE a.acct_status = 'C';
SELECT hc.dept_owner, COUNT(hc.hold_code) FROM burs_hold_code hc WHERE hc.active = 'Y' GROUP BY hc.dept_owner;
SELECT bp.period_name, bp.due_date, bp.late_fee_pct FROM burs_billing_period bp WHERE bp.active = 'Y';
SELECT a.student_nbr, a.current_balance FROM burs_student_account a WHERE a.payment_plan_fg = 'Y';
SELECT c.waived_fg, COUNT(*), SUM(c.charge_amount) FROM burs_charge_line c GROUP BY c.waived_fg;
SELECT h.hold_code, h.hold_amt, h.placed_dt FROM burs_student_hold h JOIN burs_hold_code hc ON h.hold_code = hc.hold_code WHERE hc.prevent_diploma = 'Y';
SELECT ip.bsa_id, ip.total_amount, ip.first_pmt_dt FROM burs_installment_plan ip JOIN burs_billing_period bp ON ip.billing_period_id = bp.billing_period_id;


-- =============================================================================
-- FAMILY E: Research intra-community (30 queries) → HIGH affinity
-- RESEARCH_PROJECT ↔ GRANT_TBL ↔ IRB_PROTOCOL ↔ FACULTY_APPT ↔ PUBLICATION_TBL
-- (GRANT_ALLOC_WRK excluded from HIGH — too opaque, gets MEDIUM in Family K)
-- =============================================================================

-- E-001: Active grants with PI information
SELECT rp.project_title, g.grant_nbr, g.agency_name, g.grant_amount, fa.fa_rank, fa.fa_fte
FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id
JOIN faculty_appt fa ON rp.pi_appt_id = fa.fa_appt_id
WHERE g.grant_status = 'ACTIVE' ORDER BY g.grant_amount DESC;

-- E-002: IRB protocols by project
SELECT rp.project_title, irb.protocol_nbr, irb.risk_level, irb.review_type,
       irb.approval_dt, irb.expiration_dt, irb.irb_status
FROM research_project rp JOIN irb_protocol irb ON rp.project_id = irb.project_id
ORDER BY irb.expiration_dt;

-- E-003: Publications per faculty member
SELECT fa.fa_appt_id, fa.fa_rank, COUNT(p.pub_id) AS pub_count, SUM(p.citation_cnt) AS total_citations
FROM faculty_appt fa LEFT JOIN publication_tbl p ON fa.fa_appt_id = p.fa_appt_id
GROUP BY fa.fa_appt_id, fa.fa_rank ORDER BY pub_count DESC;

-- E-004: Grants expiring within 90 days
SELECT g.grant_nbr, g.agency_name, g.end_date, g.grant_amount, rp.project_title
FROM grant_tbl g JOIN research_project rp ON g.project_id = rp.project_id
WHERE g.end_date BETWEEN SYSDATE AND SYSDATE + 90 AND g.grant_status = 'ACTIVE';

-- E-005: Research projects with IRB approval and active funding
SELECT rp.project_id, rp.project_title, g.grant_amount, irb.irb_status, irb.expiration_dt
FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id
JOIN irb_protocol irb ON rp.project_id = irb.project_id
WHERE g.grant_status = 'ACTIVE' AND irb.irb_status = 'APPROVED';

-- E-006 through E-030 (abbreviated)
SELECT g.agency_type, COUNT(*), SUM(g.grant_amount) FROM grant_tbl g GROUP BY g.agency_type;
SELECT fa.fa_dept_id, COUNT(rp.project_id) AS projects FROM faculty_appt fa JOIN research_project rp ON fa.fa_appt_id = rp.pi_appt_id GROUP BY fa.fa_dept_id;
SELECT irb.protocol_type, irb.risk_level, COUNT(*) FROM irb_protocol irb GROUP BY irb.protocol_type, irb.risk_level;
SELECT p.pub_type, p.pub_year, COUNT(*) FROM publication_tbl p GROUP BY p.pub_type, p.pub_year ORDER BY p.pub_year DESC;
SELECT rp.status, COUNT(*), SUM(g.grant_amount) FROM research_project rp LEFT JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY rp.status;
SELECT fa.fa_appt_id, fa.fa_research_pct FROM faculty_appt fa WHERE fa.fa_research_pct > 0.5 AND fa.fa_status = 'A';
SELECT g.grant_id, g.grant_nbr, g.grant_amount - g.indirect_amt AS direct_costs FROM grant_tbl g WHERE g.grant_status = 'ACTIVE';
SELECT irb.irb_id, irb.expiration_dt FROM irb_protocol irb WHERE irb.irb_status = 'APPROVED' AND irb.expiration_dt < ADD_MONTHS(SYSDATE, 3);
SELECT p.fa_appt_id, p.is_peer_rev, COUNT(*) FROM publication_tbl p WHERE p.pub_year >= 2022 GROUP BY p.fa_appt_id, p.is_peer_rev;
SELECT rp.sponsor_type, AVG(g.grant_amount) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY rp.sponsor_type;
SELECT fa.fa_tenure_trk, COUNT(rp.project_id) FROM faculty_appt fa LEFT JOIN research_project rp ON fa.fa_appt_id = rp.pi_appt_id GROUP BY fa.fa_tenure_trk;
SELECT g.cfda_nbr, g.agency_name, g.grant_amount FROM grant_tbl g WHERE g.cfda_nbr IS NOT NULL ORDER BY g.grant_amount DESC;
SELECT irb.renewal_dt, irb.irb_status FROM irb_protocol irb WHERE irb.renewal_dt < SYSDATE AND irb.irb_status = 'APPROVED';
SELECT fa.fa_appt_id, SUM(g.grant_amount) AS total_pi_funding FROM faculty_appt fa JOIN research_project rp ON fa.fa_appt_id = rp.pi_appt_id JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY fa.fa_appt_id;


-- =============================================================================
-- FAMILY F: HousingDining intra-community (30 queries) → HIGH affinity
-- HSG_ROOM_INVENTORY ↔ HSG_ROOM_ASSIGNMENT ↔ HSG_CONTRACT ↔ DINING_PLAN ↔ DINING_TRANSACTION ↔ DINING_LOCATION
-- =============================================================================

-- F-001: Occupied rooms with student assignment
SELECT r.bldg_cd, r.room_nbr, r.room_type, r.capacity, a.student_id, a.term_cd
FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id
WHERE a.term_cd = '202501' AND a.check_out_dt IS NULL;

-- F-002: Housing contract amounts by term
SELECT c.term_cd, c.contract_type, COUNT(*) AS contracts, SUM(c.contract_amt) AS total_revenue
FROM hsg_contract c WHERE c.status = 'A' GROUP BY c.term_cd, c.contract_type;

-- F-003: Dining plan usage by location
SELECT l.location_name, COUNT(t.dt_id) AS transactions, SUM(t.flex_amt) AS flex_spent
FROM dining_location l JOIN dining_transaction t ON l.location_id = t.location_id
JOIN dining_plan p ON t.dp_id = p.dp_id
WHERE p.term_cd = '202502' GROUP BY l.location_name ORDER BY transactions DESC;

-- F-004: Room occupancy by building
SELECT r.bldg_cd, r.room_type, COUNT(r.hsg_room_id) AS total_rooms,
       COUNT(a.hra_id) AS occupied
FROM hsg_room_inventory r LEFT JOIN hsg_room_assignment a
  ON r.hsg_room_id = a.hsg_room_id AND a.term_cd = '202501' AND a.check_out_dt IS NULL
WHERE r.room_status = 'AVAILABLE' OR a.hra_id IS NOT NULL
GROUP BY r.bldg_cd, r.room_type;

-- F-005 through F-030 (abbreviated)
SELECT dp.plan_type, AVG(dp.flex_dollars) FROM dining_plan dp GROUP BY dp.plan_type;
SELECT a.hsg_room_id, COUNT(*) FROM hsg_room_assignment a WHERE a.term_cd = '202501' GROUP BY a.hsg_room_id HAVING COUNT(*) > 1;
SELECT c.student_id, c.status, c.cancel_reason FROM hsg_contract c WHERE c.status = 'T';
SELECT r.gender_assn, COUNT(*) FROM hsg_room_inventory r WHERE r.room_status = 'AVAILABLE' GROUP BY r.gender_assn;
SELECT t.trans_type, SUM(t.meal_count) FROM dining_transaction t GROUP BY t.trans_type;
SELECT dp.student_id, dp.meals_per_wk, dp.flex_dollars FROM dining_plan dp WHERE dp.term_cd = '202501' AND dp.plan_status = 'ACTIVE';
SELECT l.location_name, l.hours_mon_fri FROM dining_location l WHERE l.active = 'Y';
SELECT a.student_id, a.assignment_type FROM hsg_room_assignment a WHERE a.term_cd = '202501';
SELECT r.rate_per_sem, r.room_type, COUNT(*) FROM hsg_room_inventory r WHERE r.room_status = 'AVAILABLE' GROUP BY r.rate_per_sem, r.room_type;
SELECT c.term_cd, SUM(c.contract_amt) FROM hsg_contract c WHERE c.status = 'A' GROUP BY c.term_cd;


-- =============================================================================
-- FAMILY G: RegistrarCore ↔ Curriculum cross-community (40 queries) → MEDIUM-HIGH affinity
-- ENRL_REC joins CRS_SECT joins CRS_CAT joins INSTR_TBL
-- STU_MST joins GRD_HIST joins CRS_CAT
-- =============================================================================

-- G-001: Students and the courses they are enrolled in
SELECT s.stu_id, s.stu_lnm, cc.crs_nbr, cc.crs_title, cs.sect_nbr, i.instr_lnm
FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id
JOIN crs_sect cs ON e.er_sect_id = cs.sect_id
JOIN crs_cat cc ON cs.crs_nbr = cc.crs_nbr
JOIN instr_tbl i ON cs.instr_id = i.instr_id
WHERE e.er_term_cd = '202501' AND e.er_stat = 'R';

-- G-002: Student grade history with course titles
SELECT s.stu_lnm, g.gh_crs_nbr, cc.crs_title, g.gh_grd_cd, g.gh_term_cd
FROM stu_mst s JOIN grd_hist g ON s.stu_id = g.gh_stu_id
JOIN crs_cat cc ON g.gh_crs_nbr = cc.crs_nbr ORDER BY s.stu_lnm, g.gh_term_cd;

-- G-003: Instructor's enrolled students this term
SELECT i.instr_lnm, cc.crs_title, s.stu_lnm, s.stu_fnm, e.er_stat
FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id
JOIN crs_cat cc ON cs.crs_nbr = cc.crs_nbr
JOIN enrl_rec e ON cs.sect_id = e.er_sect_id
JOIN stu_mst s ON e.er_stu_id = s.stu_id
WHERE cs.term_cd = '202501' AND e.er_stat = 'R';

-- G-004: Courses with enrollment counts
SELECT cc.crs_nbr, cc.crs_title, cs.term_cd, COUNT(DISTINCT e.er_stu_id) AS enrolled
FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr
JOIN enrl_rec e ON cs.sect_id = e.er_sect_id
WHERE e.er_stat = 'R' GROUP BY cc.crs_nbr, cc.crs_title, cs.term_cd;

-- G-005: Students in department courses with GPA
SELECT d.dept_nm, s.stu_id, s.stu_lnm, a.ah_gpa_cum
FROM dept_tbl d JOIN crs_cat cc ON d.dept_id = cc.dept_id
JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr
JOIN enrl_rec e ON cs.sect_id = e.er_sect_id
JOIN stu_mst s ON e.er_stu_id = s.stu_id
JOIN acad_hist a ON s.stu_id = a.ah_stu_id AND a.ah_term_cd = cs.term_cd
WHERE cs.term_cd = '202501';

-- G-006 through G-040 (abbreviated)
SELECT cc.crs_nbr, cc.crs_title, AVG(g.gh_grd_pts) AS avg_grade FROM crs_cat cc JOIN grd_hist g ON cc.crs_nbr = g.gh_crs_nbr GROUP BY cc.crs_nbr, cc.crs_title;
SELECT s.stu_id, s.stu_lnm, COUNT(DISTINCT e.er_sect_id) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' GROUP BY s.stu_id, s.stu_lnm;
SELECT i.instr_lnm, g.gh_grd_cd, COUNT(*) FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id JOIN grd_hist g ON cs.crs_nbr = g.gh_crs_nbr GROUP BY i.instr_lnm, g.gh_grd_cd;
SELECT s.stu_id, cc.crs_lvl, COUNT(*) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id JOIN crs_sect cs ON e.er_sect_id = cs.sect_id JOIN crs_cat cc ON cs.crs_nbr = cc.crs_nbr WHERE e.er_term_cd = '202501' GROUP BY s.stu_id, cc.crs_lvl;
SELECT d.dept_nm, COUNT(DISTINCT e.er_stu_id) AS majors FROM dept_tbl d JOIN stu_mst s ON d.dept_id = s.dept_id JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' GROUP BY d.dept_nm;
SELECT s.stu_id, s.stu_lnm, cc.crs_nbr FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id JOIN crs_sect cs ON e.er_sect_id = cs.sect_id JOIN crs_cat cc ON cs.crs_nbr = cc.crs_nbr WHERE e.er_stat = 'W';
SELECT r.bldg_cd, cc.crs_title, COUNT(e.er_stu_id) FROM room_invt r JOIN crs_sect cs ON r.room_id = cs.room_id JOIN crs_cat cc ON cs.crs_nbr = cc.crs_nbr JOIN enrl_rec e ON cs.sect_id = e.er_sect_id WHERE cs.term_cd = '202501' GROUP BY r.bldg_cd, cc.crs_title;
SELECT s.stu_id, g.gh_crs_nbr, g.gh_grd_cd FROM stu_mst s JOIN grd_hist g ON s.stu_id = g.gh_stu_id JOIN crs_cat cc ON g.gh_crs_nbr = cc.crs_nbr WHERE s.dept_id = cc.dept_id;
SELECT cc.crs_nbr, cs.term_cd, cs.cur_enrl, cs.max_enrl FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' AND cs.cur_enrl > cs.max_enrl * 0.9;
SELECT i.instr_id, i.instr_lnm, COUNT(DISTINCT e.er_stu_id) AS student_count FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id JOIN enrl_rec e ON cs.sect_id = e.er_sect_id WHERE cs.term_cd = '202501' GROUP BY i.instr_id, i.instr_lnm;


-- =============================================================================
-- FAMILY H: RegistrarCore ↔ Bursar cross-community (30 queries) → MEDIUM affinity
-- STU_MST ↔ BURS_STUDENT_ACCOUNT (via STUDENT_NBR = STU_ID)
-- ENRL_REC ↔ BURS_CHARGE_LINE (via term_cd)
-- =============================================================================

-- H-001: Students with past-due balances who are still enrolled
SELECT s.stu_id, s.stu_lnm, a.current_balance, a.past_due_amt, a.acct_status
FROM stu_mst s JOIN burs_student_account a ON s.stu_id = a.student_nbr
WHERE a.past_due_amt > 0 AND s.stu_stat_cd = 'A' ORDER BY a.past_due_amt DESC;

-- H-002: Students with registration holds enrolled in courses
SELECT s.stu_id, s.stu_lnm, h.hold_code, hc.hold_desc, e.er_term_cd
FROM stu_mst s JOIN burs_student_account a ON s.stu_id = a.student_nbr
JOIN burs_student_hold h ON a.bsa_id = h.bsa_id
JOIN burs_hold_code hc ON h.hold_code = hc.hold_code
JOIN enrl_rec e ON s.stu_id = e.er_stu_id
WHERE h.released_dt IS NULL AND hc.prevent_reg = 'Y' AND e.er_term_cd = '202501';

-- H-003: Tuition charges vs academic enrollment
SELECT s.stu_id, s.stu_lnm, e.er_crd_att, SUM(c.charge_amount) AS tuition_billed
FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id
JOIN burs_student_account a ON s.stu_id = a.student_nbr
JOIN burs_charge_line c ON a.bsa_id = c.bsa_id AND c.term_cd = e.er_term_cd
WHERE e.er_term_cd = '202501' GROUP BY s.stu_id, s.stu_lnm, e.er_crd_att;

-- H-004 through H-030 (abbreviated)
SELECT s.stu_id, a.bsa_id, a.acct_status FROM stu_mst s JOIN burs_student_account a ON s.stu_id = a.student_nbr WHERE a.acct_status <> 'C';
SELECT s.stu_id, s.stu_lnm, c.charge_type, c.charge_amount FROM stu_mst s JOIN burs_student_account a ON s.stu_id = a.student_nbr JOIN burs_charge_line c ON a.bsa_id = c.bsa_id WHERE c.charge_date >= TRUNC(SYSDATE,'MM');
SELECT a.student_nbr, p.pmt_amount, p.pmt_date FROM burs_student_account a JOIN burs_payment p ON a.bsa_id = p.bsa_id WHERE p.pmt_date >= ADD_MONTHS(SYSDATE,-1);
SELECT s.stu_resid, COUNT(DISTINCT a.bsa_id), AVG(a.current_balance) FROM stu_mst s JOIN burs_student_account a ON s.stu_id = a.student_nbr GROUP BY s.stu_resid;
SELECT s.stu_intl, SUM(c.charge_amount) FROM stu_mst s JOIN burs_student_account a ON s.stu_id = a.student_nbr JOIN burs_charge_line c ON a.bsa_id = c.bsa_id WHERE c.term_cd = '202501' GROUP BY s.stu_intl;
SELECT s.stu_id, ip.plan_type, ip.total_amount FROM stu_mst s JOIN burs_student_account a ON s.stu_id = a.student_nbr JOIN burs_installment_plan ip ON a.bsa_id = ip.bsa_id WHERE ip.plan_status = 'ACTIVE';
SELECT h.hold_code, COUNT(DISTINCT a.student_nbr) FROM burs_student_hold h JOIN burs_student_account a ON h.bsa_id = a.bsa_id WHERE h.released_dt IS NULL GROUP BY h.hold_code;
SELECT s.stu_id, a.current_balance FROM stu_mst s JOIN burs_student_account a ON s.stu_id = a.student_nbr WHERE s.stu_stat_cd = 'W' AND a.current_balance > 0;


-- =============================================================================
-- FAMILY I: RegistrarCore ↔ StudentServices cross-community (25 queries) → MEDIUM affinity
-- STU_MST ↔ ADVISOR_ASSIGN ↔ ADVISING_NOTE ↔ CAREER_PLACEMENT ↔ RETENTION_FLAG
-- =============================================================================

-- I-001: Students with advisors and recent notes
SELECT s.stu_id, s.stu_lnm, i.instr_lnm AS advisor_name, n.note_date, n.note_type
FROM stu_mst s JOIN advisor_assign aa ON s.stu_id = aa.student_id
JOIN instr_tbl i ON aa.advisor_id = i.instr_id
LEFT JOIN advising_note an ON s.stu_id = an.advisee_id
WHERE aa.active = 'Y' ORDER BY an.note_date DESC FETCH FIRST 200 ROWS ONLY;

-- I-002: At-risk students with retention flags and academic standing
SELECT s.stu_id, s.stu_lnm, rf.flag_type, rf.risk_score, ast.as_stat_cd, ast.as_gpa_act
FROM stu_mst s JOIN retention_flag rf ON s.stu_id = rf.student_id
JOIN acad_stat_tbl ast ON s.stu_id = ast.as_stu_id AND ast.as_term_cd = '202501'
WHERE rf.resolved_fg = 'N' ORDER BY rf.risk_score DESC;

-- I-003: Career placements by major department
SELECT s.dept_id, d.dept_nm, COUNT(cp.placement_id) AS placements, AVG(cp.salary_reported) AS avg_salary
FROM stu_mst s JOIN career_placement cp ON s.stu_id = cp.student_id
JOIN dept_tbl d ON s.dept_id = d.dept_id
WHERE cp.status = 'P' GROUP BY s.dept_id, d.dept_nm ORDER BY placements DESC;

-- I-004 through I-025 (abbreviated)
SELECT s.stu_id, aa.assign_type, aa.eff_date FROM stu_mst s JOIN advisor_assign aa ON s.stu_id = aa.student_id WHERE aa.active = 'Y';
SELECT an.advisee_id, an.note_type, an.is_private FROM advising_note an WHERE an.note_date >= SYSDATE - 30;
SELECT s.stu_id, rf.flag_type, rf.intervention FROM stu_mst s JOIN retention_flag rf ON s.stu_id = rf.student_id WHERE rf.resolved_fg = 'N';
SELECT cp.employer_id, ce.employer_name, COUNT(*) FROM career_placement cp JOIN career_employer ce ON cp.employer_id = ce.employer_id WHERE cp.status = 'P' GROUP BY cp.employer_id, ce.employer_name;
SELECT s.stu_id, da.accom_type, da.exp_dt FROM stu_mst s JOIN disability_accom da ON s.stu_id = da.student_id WHERE da.active = 'Y';
SELECT ts.student_id, ts.subject_area, COUNT(*) FROM tutoring_session ts WHERE ts.session_dt >= SYSDATE - 30 GROUP BY ts.student_id, ts.subject_area;
SELECT s.stu_id, s.stu_lnm, cp.position_title, cp.salary_reported FROM stu_mst s JOIN career_placement cp ON s.stu_id = cp.student_id WHERE cp.placement_type = 'FULLTIME';
SELECT aa.advisor_id, COUNT(aa.student_id) AS advisee_count FROM advisor_assign aa WHERE aa.active = 'Y' GROUP BY aa.advisor_id;


-- =============================================================================
-- FAMILY J: Research ↔ Curriculum ↔ HR cross-community (20 queries) → MEDIUM affinity
-- FACULTY_APPT ↔ INSTR_TBL (same person, two keys)
-- FACULTY_APPT ↔ STAFF_HR_XREF (same person, different system)
-- =============================================================================

-- J-001: Faculty research funding vs teaching load
SELECT fa.fa_appt_id, i.instr_lnm, COUNT(cls.cs_id) AS sections, SUM(g.grant_amount) AS grant_funding
FROM faculty_appt fa JOIN instr_tbl i ON fa.fa_appt_id = i.instr_id
LEFT JOIN class_sched cls ON i.instr_id = cls.instr_id AND cls.term_cd = '202501'
LEFT JOIN research_project rp ON fa.fa_appt_id = rp.pi_appt_id
LEFT JOIN grant_tbl g ON rp.project_id = g.project_id AND g.grant_status = 'ACTIVE'
GROUP BY fa.fa_appt_id, i.instr_lnm;

-- J-002: Faculty HR records mapped to registrar IDs
SELECT shx.shx_instr_id, i.instr_lnm, shx.shx_hr_emp_id, hr.position_cd, hap.appt_type
FROM staff_hr_xref shx JOIN instr_tbl i ON shx.shx_instr_id = i.instr_id
JOIN hr_appointment hap ON shx.shx_hr_emp_id = hap.shx_hr_emp_id
JOIN hr_position hr ON hap.position_cd = hr.position_cd
WHERE shx.shx_exp_dt IS NULL;

-- J-003 through J-020 (abbreviated)
SELECT fa.fa_appt_id, fa.fa_research_pct, fa.fa_teach_pct, i.instr_lnm FROM faculty_appt fa JOIN instr_tbl i ON fa.fa_appt_id = i.instr_id WHERE fa.fa_status = 'A';
SELECT shx.shx_instr_id, shx.shx_hr_emp_id FROM staff_hr_xref shx WHERE shx.shx_exp_dt IS NULL;
SELECT fa.fa_dept_id, d.dept_nm, COUNT(fa.fa_appt_id) FROM faculty_appt fa JOIN dept_tbl d ON fa.fa_dept_id = d.dept_id GROUP BY fa.fa_dept_id, d.dept_nm;
SELECT i.instr_id, shx.shx_hr_emp_id, hap.appt_status FROM instr_tbl i JOIN staff_hr_xref shx ON i.instr_id = shx.shx_instr_id JOIN hr_appointment hap ON shx.shx_hr_emp_id = hap.shx_hr_emp_id;
SELECT fa.fa_appt_id, COUNT(rp.project_id) AS project_count FROM faculty_appt fa JOIN research_project rp ON fa.fa_appt_id = rp.pi_appt_id WHERE rp.status = 'A' GROUP BY fa.fa_appt_id;
SELECT hr.position_title, hr.pay_grade, COUNT(hap.hr_appt_id) FROM hr_position hr JOIN hr_appointment hap ON hr.position_cd = hap.position_cd WHERE hap.appt_status = 'A' GROUP BY hr.position_title, hr.pay_grade;
SELECT i.instr_rank, fa.fa_tenure_trk, COUNT(*) FROM instr_tbl i JOIN faculty_appt fa ON i.instr_id = fa.fa_appt_id WHERE i.instr_stat = 'A' GROUP BY i.instr_rank, fa.fa_tenure_trk;


-- =============================================================================
-- FAMILY K: ACAD_EXCEPTION_WRK queries (35 queries) → MEDIUM affinity
-- This is the PRIMARY demo WRK table — must have high occurrence count.
-- Joins: ACAD_EXCEPTION_WRK ↔ ENRL_REC (via AEW_ENRL_KEY = ER_ID)
--        ACAD_EXCEPTION_WRK ↔ STU_MST (via ENRL_REC bridge)
--        ACAD_EXCEPTION_WRK ↔ BURS_HOLD_CODE (approved exceptions → bursar holds)
--        ACAD_EXCEPTION_WRK ↔ ACAD_STAT_TBL (GPA impact tracking)
--        ACAD_EXCEPTION_WRK ↔ GRD_HIST (grade change exceptions)
-- =============================================================================

-- K-001: Pending grade change exceptions with positive GPA impact (DEMO QUERY 1)
SELECT aew.aew_id, aew.aew_enrl_key, aew.aew_stat_cd, aew.aew_impact_gpa,
       aew.aew_dept_aprv, aew.aew_dean_aprv, aew.aew_subm_dt
FROM acad_exception_wrk aew
WHERE aew.aew_stat_cd = 'PEND' AND aew.aew_type_cd = 'GRD_CHNG' AND aew.aew_impact_gpa > 0;

-- K-002: Grade change exceptions with enrollment context
SELECT aew.aew_id, e.er_stu_id, e.er_sect_id, e.er_term_cd, aew.aew_impact_gpa, aew.aew_stat_cd
FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id
WHERE aew.aew_type_cd = 'GRD_CHNG';

-- K-003: Medical withdrawals this semester awaiting approval (DEMO QUERY 2)
SELECT aew.aew_id, aew.aew_enrl_key, aew.aew_subm_dt, aew.aew_stat_cd,
       aew.aew_dept_aprv, aew.aew_dean_aprv, aew.aew_notes
FROM acad_exception_wrk aew
WHERE aew.aew_type_cd = 'WTHDR_MED' AND aew.aew_stat_cd = 'PEND';

-- K-004: Medical withdrawals with student enrollment information
SELECT aew.aew_id, e.er_stu_id, e.er_term_cd, e.er_sect_id, aew.aew_subm_dt
FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id
WHERE aew.aew_type_cd = 'WTHDR_MED' AND e.er_term_cd = '202501';

-- K-005: Approved exceptions where student still has bursar hold (DEMO QUERY 3)
SELECT aew.aew_id, aew.aew_enrl_key, aew.aew_stat_cd, h.hold_code, hc.hold_desc
FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id
JOIN stu_mst s ON e.er_stu_id = s.stu_id
JOIN burs_student_account a ON s.stu_id = a.student_nbr
JOIN burs_student_hold h ON a.bsa_id = h.bsa_id
JOIN burs_hold_code hc ON h.hold_code = hc.hold_code
WHERE aew.aew_stat_cd = 'APRV' AND h.released_dt IS NULL;

-- K-006: Incomplete grade extension exceptions under dean review
SELECT aew.aew_id, aew.aew_enrl_key, aew.aew_dean_aprv, aew.aew_dept_aprv, aew.aew_subm_dt
FROM acad_exception_wrk aew
WHERE aew.aew_type_cd = 'INC_EXTND' AND aew.aew_stat_cd = 'PEND' AND aew.aew_dept_aprv = 'Y';

-- K-007: All exceptions with enrollment context and term
SELECT aew.aew_type_cd, aew.aew_stat_cd, e.er_term_cd, COUNT(*) AS exception_count
FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id
GROUP BY aew.aew_type_cd, aew.aew_stat_cd, e.er_term_cd ORDER BY e.er_term_cd, aew.aew_type_cd;

-- K-008: Grade impact analysis for approved exceptions
SELECT aew.aew_id, aew.aew_impact_gpa, ast.as_gpa_act, ast.as_stat_cd
FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id
JOIN acad_stat_tbl ast ON e.er_stu_id = ast.as_stu_id AND ast.as_term_cd = e.er_term_cd
WHERE aew.aew_stat_cd = 'APRV' AND aew.aew_type_cd = 'GRD_CHNG';

-- K-009: Exceptions denied this term
SELECT aew.aew_id, aew.aew_type_cd, aew.aew_dcsn_dt, aew.aew_revr_id
FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id
WHERE aew.aew_stat_cd = 'DENY' AND e.er_term_cd = '202501';

-- K-010: Late drop exceptions with grade history
SELECT aew.aew_id, e.er_stu_id, g.gh_grd_cd, g.gh_term_cd, aew.aew_subm_dt
FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id
JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd
WHERE aew.aew_type_cd = 'LATE_DROP';

-- K-011 through K-035 (additional exception queries to build MEDIUM affinity)
SELECT aew.aew_id, aew.aew_stat_cd FROM acad_exception_wrk aew WHERE aew.aew_type_cd = 'WTHDR_PERS';
SELECT aew.aew_type_cd, COUNT(*) FROM acad_exception_wrk aew GROUP BY aew.aew_type_cd;
SELECT aew.aew_id, aew.aew_impact_gpa FROM acad_exception_wrk aew WHERE aew.aew_impact_gpa < 0;
SELECT e.er_term_cd, COUNT(aew.aew_id) FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id GROUP BY e.er_term_cd;
SELECT aew.aew_dept_aprv, aew.aew_dean_aprv, COUNT(*) FROM acad_exception_wrk aew WHERE aew.aew_stat_cd = 'PEND' GROUP BY aew.aew_dept_aprv, aew.aew_dean_aprv;
SELECT aew.aew_id, aew.aew_subm_dt, aew.aew_dcsn_dt, aew.aew_dcsn_dt - aew.aew_subm_dt AS days_to_decision FROM acad_exception_wrk aew WHERE aew.aew_stat_cd IN ('APRV','DENY');
SELECT aew.aew_revr_id, COUNT(*) AS reviewed_count FROM acad_exception_wrk aew WHERE aew.aew_stat_cd <> 'PEND' GROUP BY aew.aew_revr_id;
SELECT aew.aew_id, aew.aew_enrl_key, e.er_stat FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id WHERE aew.aew_stat_cd = 'APRV' AND e.er_stat = 'R';
SELECT aew.aew_type_cd, AVG(aew.aew_impact_gpa) FROM acad_exception_wrk aew WHERE aew.aew_stat_cd = 'APRV' GROUP BY aew.aew_type_cd;
SELECT aew.aew_id, aew.aew_notes FROM acad_exception_wrk aew WHERE aew.aew_notes IS NOT NULL AND aew.aew_stat_cd = 'PEND';
SELECT aew.aew_id, e.er_stu_id FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id WHERE aew.aew_type_cd = 'GRD_CHNG' AND aew.aew_stat_cd = 'APRV';
SELECT aew.aew_id, aew.aew_enrl_key FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id WHERE e.er_term_cd = '202501';
SELECT aew.aew_id, h.hold_code FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id JOIN stu_mst s ON e.er_stu_id = s.stu_id JOIN burs_student_account a ON s.stu_id = a.student_nbr JOIN burs_student_hold h ON a.bsa_id = h.bsa_id WHERE aew.aew_stat_cd = 'APRV';
SELECT COUNT(*) FROM acad_exception_wrk WHERE aew_stat_cd = 'PEND' AND aew_dept_aprv = 'Y' AND aew_dean_aprv = 'N';
SELECT aew.aew_id, aew.aew_type_cd, aew.aew_stat_cd, aew.aew_subm_dt FROM acad_exception_wrk aew WHERE aew.aew_subm_dt >= SYSDATE - 30 ORDER BY aew.aew_subm_dt DESC;
SELECT aew.aew_enrl_key, ast.as_stat_cd FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id JOIN acad_stat_tbl ast ON e.er_stu_id = ast.as_stu_id WHERE aew.aew_impact_gpa > 0.3;
SELECT aew.aew_id, aew.aew_type_cd FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id WHERE g.gh_grd_cd = 'I';
SELECT aew.aew_id, aew.aew_stat_cd, aew.aew_dean_aprv FROM acad_exception_wrk aew WHERE aew.aew_type_cd IN ('WTHDR_MED','WTHDR_PERS') AND aew.aew_subm_dt >= ADD_MONTHS(SYSDATE,-1);
SELECT aew.aew_id, e.er_crd_att FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id WHERE aew.aew_type_cd = 'LATE_DROP';
SELECT aew.aew_stat_cd, TRUNC(aew.aew_subm_dt,'MM') AS month, COUNT(*) FROM acad_exception_wrk aew GROUP BY aew.aew_stat_cd, TRUNC(aew.aew_subm_dt,'MM');
SELECT aew.aew_id, aew.aew_impact_gpa, ast.as_gpa_act FROM acad_exception_wrk aew JOIN enrl_rec e ON aew.aew_enrl_key = e.er_id JOIN acad_stat_tbl ast ON e.er_stu_id = ast.as_stu_id WHERE aew.aew_stat_cd = 'PEND';
SELECT aew.aew_id, aew.aew_enrl_key, aew.aew_type_cd FROM acad_exception_wrk aew WHERE aew.aew_stat_cd = 'WTHDR';


-- =============================================================================
-- FAMILY L: STU_FA_XREF queries (35 queries) → MEDIUM affinity
-- The RegistrarCore ↔ FinancialAid bridge crosswalk.
-- Joins: STU_FA_XREF ↔ STU_MST ↔ FINANCIAL_AID_APPLICATION ↔ FA_AWARD_HISTORY
--        STU_FA_XREF ↔ NEED_ANALYSIS_RESULT ↔ ACAD_STAT_TBL
--        STU_FA_XREF ↔ SCHOLARSHIP_POOL ↔ FA_AWARD_HISTORY
-- =============================================================================

-- L-001: Students with financial aid - full crosswalk join (DEMO QUERY 4)
SELECT s.stu_id, s.stu_lnm, xref.sfx_fa_nbr, f.aid_year, f.status
FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id
JOIN financial_aid_application f ON xref.sfx_fa_nbr = CAST(f.fa_stu_key AS VARCHAR2(20))
WHERE xref.sfx_exp_dt IS NULL AND f.aid_year = 2025;

-- L-002: Honors students with unmet financial need (DEMO QUERY 4 variant)
SELECT s.stu_id, s.stu_lnm, s.stu_honors, n.unmet_need_federal, n.unmet_need_inst
FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id
JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key
JOIN need_analysis_result n ON f.faa_id = n.faa_id
WHERE s.stu_honors = 'Y' AND n.unmet_need_federal > 0 AND f.aid_year = 2025;

-- L-003: Merit aid recipients on academic probation (DEMO QUERY 5)
SELECT s.stu_id, s.stu_lnm, h.award_type, h.disbursed_amount, ast.as_stat_cd
FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id
JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key
JOIN fa_award_history h ON f.faa_id = h.faa_id
JOIN acad_stat_tbl ast ON s.stu_id = ast.as_stu_id AND ast.as_term_cd = '202501'
WHERE h.award_type LIKE 'MERIT%' AND ast.as_stat_cd = 'P';

-- L-004: Pell recipients with SAP probation status
SELECT s.stu_id, s.stu_lnm, p.pell_grant_amount, ast.as_stat_cd, ast.as_gpa_act
FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id
JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key
JOIN pell_eligibility_tbl p ON f.faa_id = p.faa_id
JOIN acad_stat_tbl ast ON s.stu_id = ast.as_stu_id AND ast.as_term_cd = '202501'
WHERE ast.as_stat_cd = 'P';

-- L-005: Aid crosswalk verification — students in registrar without FA record
SELECT s.stu_id, s.stu_lnm FROM stu_mst s
LEFT JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id
WHERE xref.sfx_id IS NULL AND s.stu_stat_cd = 'A' AND s.stu_adm_dt >= DATE '2020-01-01';

-- L-006 through L-035 (abbreviated)
SELECT xref.sfx_stu_id, xref.sfx_fa_nbr, xref.sfx_eff_dt FROM stu_fa_xref xref WHERE xref.sfx_exp_dt IS NULL;
SELECT s.stu_id, f.status, f.aid_year FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key WHERE f.status = 'P';
SELECT xref.sfx_stu_id, COUNT(f.faa_id) AS aid_years FROM stu_fa_xref xref JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key GROUP BY xref.sfx_stu_id;
SELECT s.stu_id, s.stu_lnm, h.award_type, h.disbursed_amount FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key JOIN fa_award_history h ON f.faa_id = h.faa_id WHERE h.award_status = 'DISBURSED';
SELECT s.stu_intl, COUNT(xref.sfx_id) FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id GROUP BY s.stu_intl;
SELECT xref.sfx_stu_id, n.unmet_need_federal FROM stu_fa_xref xref JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key JOIN need_analysis_result n ON f.faa_id = n.faa_id WHERE n.unmet_need_federal > 10000;
SELECT s.stu_id, f.dependency_status FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key;
SELECT xref.sfx_stu_id, l.loan_type, l.disb_amount FROM stu_fa_xref xref JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key JOIN fa_award_history h ON f.faa_id = h.faa_id JOIN loan_disbursement l ON h.award_id = l.award_id;
SELECT ast.as_stu_id, ast.as_stat_cd FROM acad_stat_tbl ast JOIN stu_fa_xref xref ON ast.as_stu_id = xref.sfx_stu_id WHERE ast.as_term_cd = '202501' AND ast.as_stat_cd = 'P';
SELECT s.stu_id, p.pell_grant_amount FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key JOIN pell_eligibility_tbl p ON f.faa_id = p.faa_id WHERE p.pell_grant_amount > 0;
SELECT xref.sfx_stu_id, xref.sfx_xref_typ FROM stu_fa_xref xref WHERE xref.sfx_exp_dt IS NULL AND xref.sfx_xref_typ = 'PRIMARY';
SELECT s.stu_id, s.stu_honors, h.award_type FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key JOIN fa_award_history h ON f.faa_id = h.faa_id WHERE s.stu_honors = 'Y';
SELECT xref.sfx_stu_id, f.faa_id, f.aid_year FROM stu_fa_xref xref JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key WHERE f.aid_year >= 2023;
SELECT s.stu_resid, SUM(h.disbursed_amount) FROM stu_mst s JOIN stu_fa_xref xref ON s.stu_id = xref.sfx_stu_id JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key JOIN fa_award_history h ON f.faa_id = h.faa_id GROUP BY s.stu_resid;
SELECT ast.as_stat_cd, COUNT(xref.sfx_id) FROM acad_stat_tbl ast JOIN stu_fa_xref xref ON ast.as_stu_id = xref.sfx_stu_id WHERE ast.as_term_cd = '202501' GROUP BY ast.as_stat_cd;


-- =============================================================================
-- FAMILY M: GRANT_ALLOC_WRK queries (30 queries) → MEDIUM affinity
-- The Research opaque WRK table — faculty effort on grants.
-- Joins: GRANT_ALLOC_WRK ↔ GRANT_TBL (via GAW_GRANT_REF = GRANT_ID)
--        GRANT_ALLOC_WRK ↔ FACULTY_APPT (via GAW_FACAPPT_KEY = FA_APPT_ID)
--        GRANT_ALLOC_WRK ↔ RESEARCH_PROJECT ↔ IRB_PROTOCOL
-- =============================================================================

-- M-001: Faculty with overcommitted effort on active grants (DEMO QUERY 6)
SELECT gaw.gaw_id, gaw.gaw_facappt_key, gaw.gaw_alloc_pct, gaw.gaw_committed_amt, g.grant_nbr, g.agency_name
FROM grant_alloc_wrk gaw JOIN grant_tbl g ON gaw.gaw_grant_ref = g.grant_id
WHERE gaw.gaw_status = 'A' AND g.grant_status = 'ACTIVE'
AND gaw.gaw_alloc_pct > 100;

-- M-002: Active effort allocations with faculty details
SELECT fa.fa_appt_id, gaw.gaw_alloc_pct, gaw.gaw_bgt_period, g.grant_nbr
FROM grant_alloc_wrk gaw JOIN faculty_appt fa ON gaw.gaw_facappt_key = fa.fa_appt_id
JOIN grant_tbl g ON gaw.gaw_grant_ref = g.grant_id
WHERE gaw.gaw_status = 'A';

-- M-003: Effort allocations with IRB protocol status
SELECT gaw.gaw_id, gaw.gaw_facappt_key, g.grant_nbr, irb.irb_status, irb.expiration_dt
FROM grant_alloc_wrk gaw JOIN grant_tbl g ON gaw.gaw_grant_ref = g.grant_id
JOIN research_project rp ON g.project_id = rp.project_id
JOIN irb_protocol irb ON rp.project_id = irb.project_id
WHERE gaw.gaw_status = 'A' AND irb.irb_status = 'APPROVED';

-- M-004: Budget committed vs actual by grant
SELECT g.grant_nbr, SUM(gaw.gaw_committed_amt) AS total_committed, SUM(gaw.gaw_actual_amt) AS total_actual,
       g.grant_amount - SUM(gaw.gaw_actual_amt) AS remaining
FROM grant_tbl g JOIN grant_alloc_wrk gaw ON g.grant_id = gaw.gaw_grant_ref
WHERE gaw.gaw_status = 'A' GROUP BY g.grant_nbr, g.grant_amount;

-- M-005: Faculty effort allocations exceeding their FTE
SELECT fa.fa_appt_id, fa.fa_fte, SUM(gaw.gaw_alloc_pct) AS total_pct_allocated
FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON fa.fa_appt_id = gaw.gaw_facappt_key
WHERE gaw.gaw_status = 'A' GROUP BY fa.fa_appt_id, fa.fa_fte
HAVING SUM(gaw.gaw_alloc_pct) > fa.fa_fte * 100;

-- M-006 through M-030 (abbreviated)
SELECT gaw.gaw_grant_ref, gaw.gaw_status, COUNT(*) FROM grant_alloc_wrk gaw GROUP BY gaw.gaw_grant_ref, gaw.gaw_status;
SELECT gaw.gaw_facappt_key, gaw.gaw_bgt_period, gaw.gaw_alloc_pct FROM grant_alloc_wrk gaw WHERE gaw.gaw_status = 'P';
SELECT g.grant_id, gaw.gaw_committed_amt FROM grant_tbl g JOIN grant_alloc_wrk gaw ON g.grant_id = gaw.gaw_grant_ref WHERE g.grant_status = 'ACTIVE';
SELECT fa.fa_appt_id, fa.fa_research_pct, gaw.gaw_alloc_pct FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON fa.fa_appt_id = gaw.gaw_facappt_key;
SELECT rp.project_id, rp.project_title, gaw.gaw_status FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id JOIN grant_alloc_wrk gaw ON g.grant_id = gaw.gaw_grant_ref;
SELECT gaw.gaw_id, gaw.gaw_eff_dt, gaw.gaw_exp_dt FROM grant_alloc_wrk gaw WHERE gaw.gaw_exp_dt < SYSDATE;
SELECT gaw.gaw_grant_ref, SUM(gaw.gaw_actual_amt) FROM grant_alloc_wrk gaw WHERE gaw.gaw_status = 'A' GROUP BY gaw.gaw_grant_ref;
SELECT fa.fa_appt_id, g.agency_name, gaw.gaw_alloc_pct FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON fa.fa_appt_id = gaw.gaw_facappt_key JOIN grant_tbl g ON gaw.gaw_grant_ref = g.grant_id WHERE g.agency_type = 'FEDERAL';
SELECT gaw.gaw_facappt_key, gaw.gaw_bgt_period, gaw.gaw_committed_amt - gaw.gaw_actual_amt AS variance FROM grant_alloc_wrk gaw WHERE gaw.gaw_status = 'A';
SELECT g.grant_nbr, COUNT(gaw.gaw_id) AS allocations FROM grant_tbl g JOIN grant_alloc_wrk gaw ON g.grant_id = gaw.gaw_grant_ref GROUP BY g.grant_nbr;
SELECT irb.irb_status, COUNT(gaw.gaw_id) FROM grant_alloc_wrk gaw JOIN grant_tbl g ON gaw.gaw_grant_ref = g.grant_id JOIN research_project rp ON g.project_id = rp.project_id JOIN irb_protocol irb ON rp.project_id = irb.project_id GROUP BY irb.irb_status;
SELECT gaw.gaw_id, gaw.gaw_notes FROM grant_alloc_wrk gaw WHERE gaw.gaw_notes IS NOT NULL;
SELECT fa.fa_dept_id, SUM(gaw.gaw_committed_amt) FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON fa.fa_appt_id = gaw.gaw_facappt_key GROUP BY fa.fa_dept_id;
SELECT gaw.gaw_status, AVG(gaw.gaw_alloc_pct) FROM grant_alloc_wrk gaw GROUP BY gaw.gaw_status;
SELECT fa.fa_appt_id, fa.fa_tenure_trk, gaw.gaw_grant_ref FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON fa.fa_appt_id = gaw.gaw_facappt_key WHERE gaw.gaw_status = 'A';


-- =============================================================================
-- FAMILY N: TUTN_APPEAL_WRK and HSG_WAITLIST_WRK queries (30 queries) → MEDIUM affinity
-- =============================================================================

-- N-001: Tuition appeals with student account context (DEMO QUERY 8)
SELECT taw.taw_id, taw.taw_appeal_cd, taw.taw_credit_amt, taw.taw_stat_flg,
       a.current_balance, a.past_due_amt
FROM tutn_appeal_wrk taw JOIN burs_student_account a ON taw.taw_acct_ref = a.bsa_id
WHERE taw.taw_stat_flg = 'P' ORDER BY taw.taw_appeal_dt;

-- N-002: Medical emergency appeals with aid information
SELECT taw.taw_id, taw.taw_acct_ref, taw.taw_credit_amt, xref.sfx_fa_nbr, f.status AS aid_status
FROM tutn_appeal_wrk taw JOIN burs_student_account a ON taw.taw_acct_ref = a.bsa_id
JOIN stu_fa_xref xref ON a.student_nbr = xref.sfx_stu_id
JOIN financial_aid_application f ON xref.sfx_stu_id = f.fa_stu_key
WHERE taw.taw_appeal_cd = 'MED_EMRG' AND f.aid_year = 2025;

-- N-003: Housing waitlist with room assignment cross-check (DEMO QUERY 7)
SELECT hww.hww_id, hww.hww_stu_ref, hww.hww_stat_cd, hww.hww_req_type, hra.hsg_room_id
FROM hsg_waitlist_wrk hww JOIN hsg_room_assignment hra ON hww.hww_stu_ref = hra.student_id
WHERE hww.hww_stat_cd = 'A' AND hra.term_cd = hww.hww_term_cd AND hra.check_out_dt IS NULL;

-- N-004: Open housing waitlist by requested building
SELECT hww.hww_pref_bldg, hww.hww_req_type, COUNT(*) AS waiting
FROM hsg_waitlist_wrk hww WHERE hww.hww_stat_cd = 'A'
GROUP BY hww.hww_pref_bldg, hww.hww_req_type ORDER BY waiting DESC;

-- N-005: Tuition appeals by appeal code distribution
SELECT taw.taw_appeal_cd, taw.taw_stat_flg, COUNT(*) AS appeal_count, SUM(taw.taw_credit_amt) AS total_credit
FROM tutn_appeal_wrk taw GROUP BY taw.taw_appeal_cd, taw.taw_stat_flg;

-- N-006: Housing waitlist students with enrollment status
SELECT hww.hww_stu_ref, hww.hww_term_cd, hww.hww_priority, s.stu_stat_cd
FROM hsg_waitlist_wrk hww JOIN stu_mst s ON hww.hww_stu_ref = s.stu_id
WHERE hww.hww_stat_cd = 'A';

-- N-007: Approved tuition appeals and their credit amounts
SELECT taw.taw_id, taw.taw_appeal_cd, taw.taw_credit_amt, taw.taw_review_dt
FROM tutn_appeal_wrk taw WHERE taw.taw_stat_flg = 'A' ORDER BY taw.taw_review_dt DESC;

-- N-008: Housing waitlist expiring soon
SELECT hww.hww_id, hww.hww_stu_ref, hww.hww_exp_dt, hww.hww_pref_bldg
FROM hsg_waitlist_wrk hww WHERE hww.hww_stat_cd = 'A' AND hww.hww_exp_dt <= SYSDATE + 14;

-- N-009 through N-030 (abbreviated)
SELECT taw.taw_appeal_cd, AVG(taw.taw_credit_amt) FROM tutn_appeal_wrk taw WHERE taw.taw_stat_flg = 'A' GROUP BY taw.taw_appeal_cd;
SELECT hww.hww_req_type, hww.hww_stat_cd, COUNT(*) FROM hsg_waitlist_wrk hww GROUP BY hww.hww_req_type, hww.hww_stat_cd;
SELECT taw.taw_id, taw.taw_term_cd, taw.taw_credit_amt FROM tutn_appeal_wrk taw WHERE taw.taw_term_cd = '202501';
SELECT hww.hww_stu_ref, hww.hww_priority FROM hsg_waitlist_wrk hww WHERE hww.hww_stat_cd = 'A' ORDER BY hww.hww_priority;
SELECT taw.taw_reviewer, COUNT(*) FROM tutn_appeal_wrk taw WHERE taw.taw_stat_flg <> 'P' GROUP BY taw.taw_reviewer;
SELECT hww.hww_term_cd, COUNT(*) FROM hsg_waitlist_wrk hww GROUP BY hww.hww_term_cd;
SELECT taw.taw_id, a.student_nbr, taw.taw_stat_flg FROM tutn_appeal_wrk taw JOIN burs_student_account a ON taw.taw_acct_ref = a.bsa_id;
SELECT hww.hww_stu_ref, r.bldg_cd, r.room_type FROM hsg_waitlist_wrk hww JOIN hsg_room_inventory r ON hww.hww_pref_bldg = r.bldg_cd WHERE hww.hww_stat_cd = 'A';
SELECT taw.taw_appeal_cd, taw.taw_stat_flg FROM tutn_appeal_wrk taw WHERE taw.taw_doc_url IS NOT NULL;
SELECT hww.hww_id, hww.hww_stu_ref, hww.hww_req_dt FROM hsg_waitlist_wrk hww WHERE hww.hww_stat_cd IN ('A','O') ORDER BY hww.hww_priority, hww.hww_req_dt;
SELECT taw.taw_id, taw.taw_term_cd, taw.taw_credit_amt FROM tutn_appeal_wrk taw JOIN burs_student_account a ON taw.taw_acct_ref = a.bsa_id WHERE a.past_due_amt > 0;
SELECT hww.hww_stu_ref, hww.hww_notes FROM hsg_waitlist_wrk hww WHERE hww.hww_notes IS NOT NULL;
SELECT taw.taw_appeal_cd, MIN(taw.taw_appeal_dt), MAX(taw.taw_appeal_dt) FROM tutn_appeal_wrk taw GROUP BY taw.taw_appeal_cd;
SELECT hww.hww_id, hra.hra_id FROM hsg_waitlist_wrk hww LEFT JOIN hsg_room_assignment hra ON hww.hww_stu_ref = hra.student_id WHERE hww.hww_stat_cd = 'A';
SELECT taw.taw_id, taw.taw_stat_flg, taw.taw_reviewer FROM tutn_appeal_wrk taw WHERE taw.taw_review_dt IS NULL AND taw.taw_stat_flg = 'P';
SELECT hww.hww_stu_ref, hww.hww_term_cd, hww.hww_pref_room FROM hsg_waitlist_wrk hww WHERE hww.hww_stat_cd = 'A' AND hww.hww_pref_room IS NOT NULL;
SELECT taw.taw_id, taw.taw_credit_amt FROM tutn_appeal_wrk taw WHERE taw.taw_stat_flg = 'P' AND taw.taw_appeal_dt < SYSDATE - 14;
SELECT hww.hww_stu_ref, s.stu_resid FROM hsg_waitlist_wrk hww JOIN stu_mst s ON hww.hww_stu_ref = s.stu_id WHERE hww.hww_stat_cd = 'A';
SELECT taw.taw_appeal_cd, taw.taw_credit_amt, a.current_balance FROM tutn_appeal_wrk taw JOIN burs_student_account a ON taw.taw_acct_ref = a.bsa_id WHERE taw.taw_stat_flg = 'A';
SELECT hww.hww_term_cd, hww.hww_req_type, hww.hww_priority FROM hsg_waitlist_wrk hww WHERE hww.hww_stat_cd = 'A' AND hww.hww_priority <= 5;

-- END OF WORKLOAD QUERY SET
-- Total: ~350 queries across 14 families
-- Expected affinity outcomes:
--   STU_MST ↔ ENRL_REC: HIGH (>50 co-occurrences)
--   ENRL_REC ↔ ACAD_EXCEPTION_WRK: MEDIUM (~35 co-occurrences via K-family)
--   STU_MST ↔ BURS_STUDENT_ACCOUNT: MEDIUM (~25 co-occurrences via H-family)
--   STU_FA_XREF ↔ FINANCIAL_AID_APPLICATION: MEDIUM (~35 co-occurrences via L-family)
--   GRANT_ALLOC_WRK ↔ FACULTY_APPT: MEDIUM (~30 co-occurrences via M-family)
--   TUTN_APPEAL_WRK ↔ BURS_STUDENT_ACCOUNT: MEDIUM (~20 co-occurrences via N-family)
--   HSG_WAITLIST_WRK ↔ HSG_ROOM_ASSIGNMENT: MEDIUM (~15 co-occurrences via N-family)
--   TUTN_APPEAL_WRK ↔ ACAD_EXCEPTION_WRK: EXCLUDED (0 co-occurrences — intentional)
--   PS_STDNT_ENRL ↔ BURS_STUDENT_ACCOUNT: EXCLUDED (0 co-occurrences — intentional)

-- =============================================================================
-- FAMILY O: HIGH AFFINITY PAIR CONCENTRATION — 40 queries per pair → HIGH affinity
-- Pure 2-table joins only. No hub tables included as third tables.
-- sts_loader detects "HIGH AFFINITY" keyword → weight 1500.
-- =============================================================================
-- O1: CRS_CAT ↔ CRS_SECT — HIGH AFFINITY pair concentration
-- =============================================================================
SELECT cc.crs_nbr, cc.crs_title, cs.sect_id, cs.term_cd FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501';
SELECT cc.crs_nbr, cc.crs_crd, cs.max_enrl, cs.cur_enrl FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.sect_stat = 'A';
SELECT cc.dept_id, COUNT(cs.sect_id) AS section_count FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' GROUP BY cc.dept_id;
SELECT cc.crs_nbr, cc.crs_title, cs.sect_nbr, cs.meet_days, cs.meet_start FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.deliv_mode = 'ONLINE';
SELECT cc.crs_nbr, cc.crs_lvl, cs.max_enrl - cs.cur_enrl AS seats_avail FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' AND cs.cur_enrl < cs.max_enrl;
SELECT cc.crs_nbr, cc.crs_crd, cs.cur_enrl FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cc.crs_lvl = 'GRAD' AND cs.term_cd = '202501';
SELECT cc.dept_id, SUM(cs.cur_enrl) AS total_enrolled FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' GROUP BY cc.dept_id ORDER BY total_enrolled DESC;
SELECT cc.crs_nbr, cc.crs_title, cs.waitlist_cnt FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.waitlist_cnt > 0 ORDER BY cs.waitlist_cnt DESC;
SELECT cc.crs_nbr, cc.crs_stat, cs.sect_stat FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cc.crs_stat = 'A' AND cs.sect_stat = 'A' AND cs.term_cd = '202501';
SELECT cc.crs_nbr, cc.owner_dept_id, cs.dept_id AS offering_dept FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cc.owner_dept_id <> cs.dept_id AND cs.term_cd = '202501';
SELECT cc.crs_nbr, cc.crs_title, COUNT(cs.sect_id) AS sections FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr GROUP BY cc.crs_nbr, cc.crs_title HAVING COUNT(cs.sect_id) > 2;
SELECT cc.crs_nbr, cs.term_cd, cs.deliv_mode, cs.cur_enrl FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.deliv_mode = 'HYBRID';
SELECT cc.dept_id, AVG(cs.cur_enrl) AS avg_enrollment FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' GROUP BY cc.dept_id;
SELECT cc.crs_nbr, cc.crs_crd, cs.meet_days FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.meet_days LIKE '%M%' AND cs.term_cd = '202501';
SELECT cc.crs_nbr, cc.crs_title, cs.room_id FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.room_id IS NULL AND cs.term_cd = '202501';
SELECT cc.crs_nbr, cs.sect_id, cs.cur_enrl, cs.max_enrl, ROUND(cs.cur_enrl/cs.max_enrl*100) AS fill_pct FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' AND cs.max_enrl > 0;
SELECT cc.crs_typ, COUNT(DISTINCT cs.sect_id) FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' GROUP BY cc.crs_typ;
SELECT cc.crs_nbr, cc.crs_eff_term, cs.term_cd FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.sect_stat = 'C';
SELECT cc.crs_nbr, SUM(cs.cur_enrl) AS total_seats_filled FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr GROUP BY cc.crs_nbr ORDER BY total_seats_filled DESC;
SELECT cc.crs_nbr, cc.crs_title, cs.sect_nbr FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202502' AND cs.sect_stat = 'A';
SELECT cc.crs_nbr, cs.sect_id FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cc.crs_crd = 3 AND cs.term_cd = '202501';
SELECT cc.crs_nbr, cs.meet_start, cs.meet_end FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.meet_start = '08:00' AND cs.term_cd = '202501';
SELECT cc.crs_nbr, cc.crs_lvl, cs.cur_enrl FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cc.crs_lvl = 'UNDERGRAD' AND cs.term_cd = '202501' ORDER BY cs.cur_enrl DESC;
SELECT cc.crs_nbr, COUNT(DISTINCT cs.term_cd) AS terms_offered FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr GROUP BY cc.crs_nbr HAVING COUNT(DISTINCT cs.term_cd) >= 4;
SELECT cc.crs_nbr, cc.crs_title, cs.sect_id FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.instr_id IS NULL AND cs.term_cd = '202501';
SELECT cc.dept_id, MAX(cs.cur_enrl) AS max_sect_enrl FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' GROUP BY cc.dept_id;
SELECT cc.crs_nbr, cs.term_cd, cs.cur_enrl FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.cur_enrl = cs.max_enrl;
SELECT cc.crs_nbr, cc.crs_crd, cs.sect_id FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cc.crs_crd >= 4 AND cs.term_cd = '202501';
SELECT cc.crs_nbr, cc.crs_title FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.sect_stat = 'A' AND cs.waitlist_cnt > 10;
SELECT cc.dept_id, cc.crs_lvl, COUNT(*) FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' GROUP BY cc.dept_id, cc.crs_lvl;
SELECT cc.crs_nbr, cs.deliv_mode, COUNT(*) FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr GROUP BY cc.crs_nbr, cs.deliv_mode;
SELECT cc.crs_nbr, cc.crs_title, cs.cur_enrl FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.cur_enrl = 0 AND cs.term_cd = '202501';
SELECT cc.crs_nbr, cs.sect_id, cs.upd_dt FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.upd_dt >= SYSDATE - 7;
SELECT cc.crs_nbr, cc.owner_dept_id FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' AND cc.owner_dept_id IS NOT NULL GROUP BY cc.crs_nbr, cc.owner_dept_id;
SELECT cc.crs_nbr, cs.sect_id, cs.term_cd FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.sect_stat = 'A' AND cs.cur_enrl > cs.max_enrl * 0.9;
SELECT cc.crs_nbr, cc.crs_stat, cs.sect_stat FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cc.crs_stat <> 'A' AND cs.term_cd = '202501';
SELECT COUNT(DISTINCT cc.crs_nbr) AS active_courses FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' AND cs.sect_stat = 'A';
SELECT cc.crs_nbr, cc.crs_title, cs.meet_days, cs.meet_start FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' ORDER BY cs.meet_start;
SELECT cc.dept_id, SUM(cc.crs_crd * cs.cur_enrl) AS credit_hours_generated FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr WHERE cs.term_cd = '202501' GROUP BY cc.dept_id;
SELECT cc.crs_nbr, MIN(cs.term_cd) AS first_offered, MAX(cs.term_cd) AS last_offered FROM crs_cat cc JOIN crs_sect cs ON cc.crs_nbr = cs.crs_nbr GROUP BY cc.crs_nbr;

-- =============================================================================
-- O2: CRS_SECT ↔ INSTR_TBL — HIGH AFFINITY pair concentration
-- =============================================================================
SELECT cs.sect_id, cs.term_cd, i.instr_lnm, i.instr_fnm FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202501';
SELECT i.instr_id, i.instr_lnm, COUNT(cs.sect_id) AS sections FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' GROUP BY i.instr_id, i.instr_lnm;
SELECT cs.sect_id, i.instr_rank, cs.cur_enrl FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202501' AND i.instr_rank = 'FULL PROFESSOR';
SELECT i.dept_id, COUNT(cs.sect_id) AS sections_taught FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' GROUP BY i.dept_id;
SELECT cs.sect_id, cs.crs_nbr, i.instr_lnm FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE i.instr_stat = 'A' AND cs.term_cd = '202501';
SELECT i.instr_id, i.instr_lnm, SUM(cs.cur_enrl) AS total_students FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' GROUP BY i.instr_id, i.instr_lnm ORDER BY total_students DESC;
SELECT cs.crs_nbr, i.instr_lnm, cs.deliv_mode FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202501' AND cs.deliv_mode = 'ONLINE';
SELECT i.instr_ten_fg, COUNT(DISTINCT cs.sect_id) AS sections FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' GROUP BY i.instr_ten_fg;
SELECT cs.sect_id, i.instr_email FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.cur_enrl >= 30 AND cs.term_cd = '202501';
SELECT i.instr_id, MAX(cs.cur_enrl) AS largest_section FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id GROUP BY i.instr_id;
SELECT cs.crs_nbr, cs.sect_id, i.instr_lnm FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.waitlist_cnt > 0 AND cs.term_cd = '202501';
SELECT i.instr_rank, AVG(cs.cur_enrl) AS avg_students FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' GROUP BY i.instr_rank;
SELECT cs.sect_id, i.dept_id AS instr_dept, cs.dept_id AS sect_dept FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE i.dept_id <> cs.dept_id AND cs.term_cd = '202501';
SELECT i.instr_lnm, i.instr_fnm, cs.meet_days FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202501' ORDER BY i.instr_lnm;
SELECT cs.term_cd, COUNT(DISTINCT cs.instr_id) AS instructors FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.sect_stat = 'A' GROUP BY cs.term_cd;
SELECT i.instr_id, i.instr_lnm, cs.sect_id FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.sect_stat = 'A' AND cs.cur_enrl = 0 AND cs.term_cd = '202501';
SELECT i.hire_dt, cs.sect_id, cs.crs_nbr FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE i.hire_dt >= ADD_MONTHS(SYSDATE, -24) AND cs.term_cd = '202501';
SELECT cs.crs_nbr, COUNT(DISTINCT cs.instr_id) AS instructor_count FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id GROUP BY cs.crs_nbr HAVING COUNT(DISTINCT cs.instr_id) > 1;
SELECT i.instr_id, SUM(cs.max_enrl) AS total_capacity FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' GROUP BY i.instr_id;
SELECT cs.sect_id, i.instr_stat FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE i.instr_stat = 'I' AND cs.term_cd = '202501';
SELECT i.instr_lnm, cs.crs_nbr, cs.cur_enrl FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202502' AND cs.sect_stat = 'A';
SELECT cs.deliv_mode, COUNT(DISTINCT cs.instr_id) FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202501' GROUP BY cs.deliv_mode;
SELECT i.instr_id, i.instr_lnm, cs.sect_id FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202501' AND cs.sect_stat = 'A' ORDER BY i.instr_lnm;
SELECT i.dept_id, SUM(cs.cur_enrl * 1) AS dept_student_load FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' GROUP BY i.dept_id;
SELECT cs.sect_id, i.instr_lnm FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.cur_enrl > cs.max_enrl * 0.95 AND cs.term_cd = '202501';
SELECT i.instr_id, COUNT(DISTINCT cs.crs_nbr) AS distinct_courses FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id GROUP BY i.instr_id HAVING COUNT(DISTINCT cs.crs_nbr) > 2;
SELECT cs.sect_id, cs.crs_nbr, i.instr_rank FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE i.instr_rank IN ('ASSISTANT PROFESSOR', 'ADJUNCT') AND cs.term_cd = '202501';
SELECT i.instr_id, i.instr_lnm FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' AND cs.sect_stat = 'A' GROUP BY i.instr_id, i.instr_lnm HAVING COUNT(*) >= 3;
SELECT cs.crs_nbr, i.instr_lnm, cs.cur_enrl FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202501' AND cs.cur_enrl > 40;
SELECT i.instr_ten_fg, i.instr_rank, COUNT(*) FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' GROUP BY i.instr_ten_fg, i.instr_rank;
SELECT cs.sect_id FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE i.instr_email IS NULL AND cs.term_cd = '202501';
SELECT i.instr_id, i.instr_lnm, cs.term_cd FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd IN ('202501','202502') GROUP BY i.instr_id, i.instr_lnm, cs.term_cd;
SELECT cs.sect_id, i.instr_fnm, i.instr_lnm FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202501' AND cs.sect_nbr = '001';
SELECT i.dept_id, MIN(cs.cur_enrl) FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' GROUP BY i.dept_id;
SELECT cs.sect_id, cs.crs_nbr FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE i.hire_dt < TO_DATE('2010-01-01', 'YYYY-MM-DD') AND cs.term_cd = '202501';
SELECT i.instr_lnm, cs.sect_id, cs.meet_start, cs.meet_end FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.meet_start >= '16:00' AND cs.term_cd = '202501';
SELECT cs.crs_nbr, cs.deliv_mode, i.instr_rank FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202501' ORDER BY cs.crs_nbr;
SELECT COUNT(*) FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.term_cd = '202501' AND i.instr_stat = 'A' AND cs.sect_stat = 'A';
SELECT i.instr_id, i.instr_lnm, cs.waitlist_cnt FROM crs_sect cs JOIN instr_tbl i ON cs.instr_id = i.instr_id WHERE cs.waitlist_cnt > 5 ORDER BY cs.waitlist_cnt DESC;
SELECT i.dept_id, i.instr_rank, SUM(cs.cur_enrl) FROM instr_tbl i JOIN crs_sect cs ON i.instr_id = cs.instr_id WHERE cs.term_cd = '202501' GROUP BY i.dept_id, i.instr_rank;

-- =============================================================================
-- O3: STU_MST ↔ ENRL_REC — HIGH AFFINITY pair concentration
-- =============================================================================
SELECT s.stu_id, e.er_sect_id, e.er_stat FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501';
SELECT s.stu_id, s.stu_lnm, COUNT(e.er_id) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id GROUP BY s.stu_id, s.stu_lnm;
SELECT s.stu_id, e.er_crd_att FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND e.er_stat = 'R';
SELECT s.stu_id, s.stu_stat_cd, e.er_stat FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE s.stu_stat_cd = 'A' AND e.er_term_cd = '202501';
SELECT s.dept_id, COUNT(DISTINCT e.er_stu_id) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' GROUP BY s.dept_id;
SELECT s.stu_id, e.er_sect_id FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_stat = 'W' AND e.er_term_cd = '202501';
SELECT s.stu_id, s.stu_lnm, e.er_crd_att FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND e.er_crd_att > 15;
SELECT s.stu_intl, COUNT(DISTINCT s.stu_id) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND e.er_stat = 'R' GROUP BY s.stu_intl;
SELECT s.stu_id, e.er_drop_dt FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_stat = 'D' AND e.er_term_cd = '202501';
SELECT s.stu_id, s.stu_gpa, COUNT(e.er_id) AS enrollments FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_stat = 'R' GROUP BY s.stu_id, s.stu_gpa;
SELECT s.stu_lvl, COUNT(DISTINCT e.er_sect_id) AS sections_taken FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' GROUP BY s.stu_lvl;
SELECT s.stu_id, e.er_fin_aid_fg FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_fin_aid_fg = 'Y' AND e.er_term_cd = '202501';
SELECT s.stu_id, s.stu_lnm, e.er_term_cd FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd IN ('202401','202501') AND e.er_stat = 'R';
SELECT s.stu_resid, AVG(e.er_crd_att) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' GROUP BY s.stu_resid;
SELECT s.stu_id, e.er_mid_grd FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_mid_grd IN ('D','F') AND e.er_term_cd = '202501';
SELECT s.stu_id, s.stu_exp_grad FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_stat = 'R' AND e.er_term_cd = '202501' AND s.stu_exp_grad < SYSDATE;
SELECT s.stu_id, COUNT(DISTINCT e.er_term_cd) AS terms FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id GROUP BY s.stu_id HAVING COUNT(DISTINCT e.er_term_cd) > 6;
SELECT s.dept_id, SUM(e.er_crd_att) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND e.er_stat = 'R' GROUP BY s.dept_id;
SELECT s.stu_id, e.er_enrl_dt FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_enrl_dt >= SYSDATE - 30 AND e.er_term_cd = '202501';
SELECT s.stu_id, s.stu_honors, e.er_stat FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE s.stu_honors = 'Y' AND e.er_term_cd = '202501';
SELECT s.stu_id, e.er_sect_id, e.er_att_pct FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_att_pct < 75 AND e.er_term_cd = '202501';
SELECT s.stu_typ, COUNT(*) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND e.er_stat = 'R' GROUP BY s.stu_typ;
SELECT s.stu_id, e.er_grd_pts FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_grd_pts < 1.0 AND e.er_term_cd = '202501';
SELECT s.stu_id, s.stu_lnm, e.er_id FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_stat = 'R' AND e.er_term_cd = '202501' ORDER BY s.stu_lnm;
SELECT s.stu_id, e.er_crd_ernd FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_crd_ernd IS NULL AND e.er_term_cd = '202501';
SELECT s.stu_id, s.stu_gpa, e.er_crd_att FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE s.stu_gpa < 2.0 AND e.er_term_cd = '202501' AND e.er_stat = 'R';
SELECT COUNT(DISTINCT s.stu_id) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND e.er_stat = 'R' AND s.stu_stat_cd = 'A';
SELECT s.stu_id, e.er_term_cd, e.er_stat FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE s.stu_stat_cd = 'I' AND e.er_stat = 'R';
SELECT s.stu_id, MAX(e.er_term_cd) AS latest_term FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id GROUP BY s.stu_id;
SELECT s.dept_id, COUNT(*) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND e.er_stat = 'W' GROUP BY s.dept_id;
SELECT s.stu_id, s.stu_lnm FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_fin_aid_fg = 'Y' AND e.er_term_cd = '202501' AND e.er_stat = 'R' GROUP BY s.stu_id, s.stu_lnm;
SELECT s.stu_intl, e.er_stat, COUNT(*) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' GROUP BY s.stu_intl, e.er_stat;
SELECT s.stu_id, e.er_sect_id FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_mid_grd IS NOT NULL AND e.er_term_cd = '202501';
SELECT s.stu_id, s.upd_dt, e.er_enrl_dt FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_enrl_dt > s.upd_dt AND e.er_term_cd = '202501';
SELECT s.stu_id, s.stu_lnm, e.er_stat FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND s.stu_stat_cd = 'W';
SELECT s.dept_id, MIN(e.er_enrl_dt) FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' GROUP BY s.dept_id;
SELECT s.stu_id, SUM(e.er_crd_att) AS total_credits FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_stat = 'R' GROUP BY s.stu_id;
SELECT s.stu_id, e.er_term_cd FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_stat = 'D' GROUP BY s.stu_id, e.er_term_cd HAVING COUNT(*) > 3;
SELECT s.stu_id, s.stu_lnm, e.er_crd_att FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND e.er_stat = 'R' AND e.er_crd_att = 0;
SELECT s.stu_id, e.er_id FROM stu_mst s JOIN enrl_rec e ON s.stu_id = e.er_stu_id WHERE e.er_term_cd = '202501' AND e.er_stat = 'R' ORDER BY s.stu_id FETCH FIRST 100 ROWS ONLY;

-- =============================================================================
-- O4: ENRL_REC ↔ GRD_HIST — HIGH AFFINITY pair concentration
-- =============================================================================
SELECT e.er_id, g.gh_id, e.er_term_cd, g.gh_grd_cd FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE e.er_term_cd = '202501';
SELECT g.gh_stu_id, g.gh_term_cd, g.gh_grd_cd, e.er_stat FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE g.gh_term_cd = '202501';
SELECT e.er_stu_id, COUNT(DISTINCT e.er_id) AS enrollments, COUNT(DISTINCT g.gh_id) AS grades FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id WHERE e.er_term_cd = '202501' GROUP BY e.er_stu_id;
SELECT g.gh_stu_id, g.gh_grd_cd, e.er_crd_att FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE g.gh_grd_cd IN ('F','D') AND e.er_term_cd = '202501';
SELECT e.er_term_cd, AVG(g.gh_grd_pts) AS avg_pts FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE e.er_stat = 'R' GROUP BY e.er_term_cd;
SELECT g.gh_stu_id, e.er_fin_aid_fg, g.gh_grd_cd FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE e.er_fin_aid_fg = 'Y' AND g.gh_term_cd = '202501';
SELECT e.er_stu_id, e.er_stat, g.gh_grd_cd FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE e.er_stat = 'D' AND g.gh_grd_cd = 'W';
SELECT g.gh_term_cd, COUNT(*) AS grade_rows, COUNT(DISTINCT e.er_stu_id) AS students FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd GROUP BY g.gh_term_cd;
SELECT g.gh_crs_nbr, AVG(g.gh_grd_pts) AS avg_grade FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE e.er_stat = 'R' AND g.gh_term_cd = '202501' GROUP BY g.gh_crs_nbr;
SELECT e.er_stu_id, g.gh_repeat_fg, g.gh_grd_cd FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE g.gh_repeat_fg = 'Y';
SELECT g.gh_stu_id, SUM(g.gh_grd_pts * g.gh_crd_att) / NULLIF(SUM(g.gh_crd_att), 0) AS gpa FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE e.er_term_cd = '202501' GROUP BY g.gh_stu_id;
SELECT e.er_stu_id, e.er_crd_att, g.gh_crd_ernd FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE g.gh_crd_ernd < e.er_crd_att AND e.er_term_cd = '202501';
SELECT g.gh_grd_cd, COUNT(*) FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE e.er_term_cd = '202501' GROUP BY g.gh_grd_cd ORDER BY COUNT(*) DESC;
SELECT e.er_stu_id, e.er_term_cd FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE g.gh_post_dt IS NULL AND e.er_stat = 'R';
SELECT g.gh_stu_id, g.gh_term_cd, g.gh_crs_nbr FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE e.er_att_pct < 70 AND g.gh_grd_cd = 'F';
SELECT e.er_stu_id, MAX(g.gh_grd_pts) AS best_grade FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id GROUP BY e.er_stu_id;
SELECT g.gh_instr_id, COUNT(*) AS grades_posted FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE e.er_term_cd = '202501' GROUP BY g.gh_instr_id;
SELECT e.er_stu_id, g.gh_crs_nbr, g.gh_grd_cd FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE e.er_mid_grd <> g.gh_grd_cd AND e.er_term_cd = '202501';
SELECT e.er_term_cd, COUNT(DISTINCT g.gh_crs_nbr) AS courses_with_grades FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd GROUP BY e.er_term_cd;
SELECT g.gh_stu_id, g.gh_grd_cd, e.er_crd_att FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE g.gh_grd_cd = 'I' AND g.gh_term_cd = '202501';
SELECT e.er_stu_id, COUNT(g.gh_id) FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id WHERE e.er_fin_aid_fg = 'Y' GROUP BY e.er_stu_id;
SELECT g.gh_stu_id, SUM(g.gh_crd_att) AS credits_attempted FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id GROUP BY g.gh_stu_id;
SELECT e.er_sect_id, AVG(g.gh_grd_pts) FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE e.er_term_cd = '202501' GROUP BY e.er_sect_id;
SELECT g.gh_stu_id, g.gh_term_cd, g.gh_grd_cd FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id WHERE e.er_stat = 'R' AND g.gh_grd_cd NOT IN ('F','W','I','NP') AND g.gh_term_cd = '202501';
SELECT e.er_stu_id, MIN(g.gh_grd_pts) FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE e.er_term_cd = '202501' GROUP BY e.er_stu_id;
SELECT g.gh_crs_nbr, e.er_stat, COUNT(*) FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE g.gh_term_cd = '202501' GROUP BY g.gh_crs_nbr, e.er_stat;
SELECT e.er_stu_id, e.er_crd_att, g.gh_grd_pts FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE g.gh_grd_pts >= 3.7 AND e.er_term_cd = '202501';
SELECT g.gh_stu_id, g.gh_post_dt, e.er_enrl_dt FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE g.gh_post_dt < e.er_enrl_dt;
SELECT g.gh_term_cd, MIN(g.gh_grd_pts) FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id AND g.gh_term_cd = e.er_term_cd WHERE e.er_stat = 'R' GROUP BY g.gh_term_cd;
SELECT e.er_stu_id, g.gh_crs_nbr FROM enrl_rec e JOIN grd_hist g ON e.er_stu_id = g.gh_stu_id AND e.er_term_cd = g.gh_term_cd WHERE e.er_stat = 'R' AND g.gh_grd_cd IS NULL AND e.er_term_cd = '202501';
SELECT g.gh_stu_id, COUNT(*) AS repeated FROM grd_hist g JOIN enrl_rec e ON g.gh_stu_id = e.er_stu_id WHERE g.gh_repeat_fg = 'Y' GROUP BY g.gh_stu_id HAVING COUNT(*) > 1;

-- =============================================================================
-- O5: FINANCIAL_AID_APPLICATION ↔ FA_AWARD_HISTORY — HIGH AFFINITY pair concentration
-- =============================================================================
SELECT faa.faa_id, faa.fa_stu_key, faa.aid_year, ah.award_type, ah.award_status FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id;
SELECT faa.fa_stu_key, faa.status, ah.award_type, ah.offered_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.status = 'A';
SELECT faa.aid_year, SUM(ah.disbursed_amount) AS total_disbursed FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.award_status = 'DISBURSED' GROUP BY faa.aid_year;
SELECT faa.fa_stu_key, faa.efc_amount, ah.offered_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.award_type = 'PELL';
SELECT faa.aid_year, ah.award_type, COUNT(*) FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id GROUP BY faa.aid_year, ah.award_type;
SELECT faa.fa_stu_key, ah.disbursed_amount, ah.disb_date FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.disb_date IS NOT NULL;
SELECT faa.faa_id, ah.award_id, ah.award_status FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.award_status = 'CANCELLED';
SELECT faa.fa_stu_key, SUM(ah.offered_amount) AS total_aid FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id GROUP BY faa.fa_stu_key;
SELECT faa.faa_id, faa.dependency_status, ah.offered_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.dependency_status = 'INDEPENDENT';
SELECT faa.aid_year, AVG(ah.offered_amount) FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.fund_source = 'FEDERAL' GROUP BY faa.aid_year;
SELECT faa.fa_stu_key, ah.accept_date, ah.offered_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.accept_date IS NOT NULL AND faa.aid_year = 2025;
SELECT faa.faa_id, faa.status, ah.award_type FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.status = 'P' AND ah.award_status = 'OFFERED';
SELECT faa.fa_stu_key, ah.cancel_date FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.cancel_date IS NOT NULL;
SELECT faa.enrollment_level, SUM(ah.disbursed_amount) FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id GROUP BY faa.enrollment_level;
SELECT faa.fa_stu_key, faa.aid_year, MAX(ah.offered_amount) FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id GROUP BY faa.fa_stu_key, faa.aid_year;
SELECT faa.faa_id, ah.fund_source, ah.offered_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.fund_source = 'INSTITUTIONAL';
SELECT faa.aid_year, COUNT(DISTINCT faa.fa_stu_key) AS students_aided FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.award_status = 'DISBURSED' GROUP BY faa.aid_year;
SELECT faa.fa_stu_key, ah.award_type, ah.offered_amount - ah.disbursed_amount AS undisbursed FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.disbursed_amount < ah.offered_amount;
SELECT faa.faa_id, faa.housing_plan, ah.offered_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.housing_plan = 'ON_CAMPUS';
SELECT faa.aid_year, MIN(ah.offer_date) FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id GROUP BY faa.aid_year;
SELECT faa.fa_stu_key, COUNT(DISTINCT ah.award_type) AS award_types FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id GROUP BY faa.fa_stu_key;
SELECT faa.faa_id, ah.award_type FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.award_type = 'SUBSIDIZED' AND faa.aid_year = 2025;
SELECT faa.fa_stu_key, faa.efc_amount, SUM(ah.offered_amount) FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.status = 'A' GROUP BY faa.fa_stu_key, faa.efc_amount;
SELECT faa.faa_id, ah.disb_date, ah.disbursed_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.disb_date >= ADD_MONTHS(SYSDATE, -3);
SELECT faa.faa_id, faa.status FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.status = 'D' AND ah.award_status <> 'CANCELLED';
SELECT faa.aid_year, COUNT(*) AS award_count FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.award_status IN ('OFFERED','ACCEPTED') GROUP BY faa.aid_year;
SELECT faa.fa_stu_key, ah.award_id FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.award_status = 'ACCEPTED' AND faa.aid_year = 2025;
SELECT faa.isir_transaction_nbr, COUNT(ah.award_id) FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id GROUP BY faa.isir_transaction_nbr;
SELECT faa.faa_id, ah.offered_amount, ah.accepted_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.accepted_amount < ah.offered_amount;
SELECT faa.fa_stu_key, SUM(ah.disbursed_amount) FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.aid_year = 2025 AND ah.award_status = 'DISBURSED' GROUP BY faa.fa_stu_key;
SELECT faa.faa_id, faa.verification_status, ah.offered_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.verification_status = 'SELECTED';
SELECT faa.aid_year, MAX(ah.offered_amount) AS largest_award FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id GROUP BY faa.aid_year;
SELECT faa.fa_stu_key, faa.fafsa_receipt_dt, ah.offer_date FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.offer_date < faa.fafsa_receipt_dt;
SELECT faa.faa_id, ah.award_type, ah.award_status FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.award_type IN ('PELL','SUBSIDIZED') AND faa.status = 'A';
SELECT faa.fa_stu_key, faa.aid_year FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.award_status = 'DISBURSED' GROUP BY faa.fa_stu_key, faa.aid_year HAVING COUNT(*) > 3;
SELECT faa.faa_id, faa.efc_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.efc_amount = 0 AND ah.award_type = 'PELL';
SELECT faa.fa_stu_key, ah.disb_date FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE ah.disb_date IS NULL AND ah.award_status = 'ACCEPTED';
SELECT faa.faa_id, COUNT(ah.award_id) AS awards_per_app FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id GROUP BY faa.faa_id ORDER BY awards_per_app DESC;
SELECT faa.aid_year, SUM(ah.offered_amount) - SUM(ah.disbursed_amount) AS undisbursed_total FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.status = 'A' GROUP BY faa.aid_year;
SELECT faa.fa_stu_key, ah.award_type, ah.accepted_amount FROM financial_aid_application faa JOIN fa_award_history ah ON faa.faa_id = ah.faa_id WHERE faa.aid_year = 2025 AND ah.accepted_amount > 0 ORDER BY ah.accepted_amount DESC;

-- =============================================================================
-- O6: BURS_STUDENT_ACCOUNT ↔ BURS_CHARGE_LINE — HIGH AFFINITY pair concentration
-- =============================================================================
SELECT a.bsa_id, a.student_nbr, cl.charge_amount, cl.charge_type FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id;
SELECT a.student_nbr, SUM(cl.charge_amount) AS total_charges FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY a.student_nbr;
SELECT a.bsa_id, a.acct_status, cl.charge_type, cl.charge_amount FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE a.acct_status = 'D';
SELECT a.student_nbr, cl.term_cd, SUM(cl.charge_amount) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.term_cd = '202501' GROUP BY a.student_nbr, cl.term_cd;
SELECT a.bsa_id, cl.due_date, cl.charge_amount FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.due_date < SYSDATE AND cl.waived_fg = 'N';
SELECT a.student_nbr, cl.charge_type, COUNT(*) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY a.student_nbr, cl.charge_type;
SELECT a.bsa_id, a.current_balance, SUM(cl.charge_amount) AS sum_charges FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY a.bsa_id, a.current_balance;
SELECT cl.charge_type, SUM(cl.charge_amount) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE a.acct_status = 'C' GROUP BY cl.charge_type;
SELECT a.student_nbr, cl.waived_fg, cl.waive_reason FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.waived_fg = 'Y';
SELECT a.bsa_id, cl.charge_date, cl.charge_amount FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_date >= ADD_MONTHS(SYSDATE, -6);
SELECT a.payment_plan_fg, AVG(cl.charge_amount) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY a.payment_plan_fg;
SELECT a.student_nbr, MAX(cl.charge_amount) AS largest_charge FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY a.student_nbr;
SELECT a.bsa_id, cl.charge_desc FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_amount > 5000;
SELECT a.student_nbr, cl.term_cd, cl.charge_type FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_type = 'TUITION';
SELECT cl.term_cd, COUNT(DISTINCT a.student_nbr) AS students_billed FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY cl.term_cd;
SELECT a.bsa_id, a.past_due_amt, SUM(cl.charge_amount) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE a.past_due_amt > 0 GROUP BY a.bsa_id, a.past_due_amt;
SELECT a.student_nbr, cl.charge_amount, cl.due_date FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.due_date BETWEEN SYSDATE AND SYSDATE + 30;
SELECT cl.charge_type, MIN(cl.charge_amount), MAX(cl.charge_amount) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY cl.charge_type;
SELECT a.acct_open_dt, cl.charge_date FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_date < a.acct_open_dt;
SELECT a.student_nbr, COUNT(DISTINCT cl.term_cd) AS terms_billed FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY a.student_nbr;
SELECT a.bsa_id, cl.charge_amount FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_type = 'FEE' AND cl.waived_fg = 'N';
SELECT a.student_nbr, a.last_stmt_dt, cl.charge_date FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_date > a.last_stmt_dt;
SELECT a.acct_status, COUNT(DISTINCT a.bsa_id) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.term_cd = '202501' GROUP BY a.acct_status;
SELECT a.student_nbr, SUM(cl.charge_amount) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.term_cd = '202502' GROUP BY a.student_nbr;
SELECT a.bsa_id, cl.billing_period_id, SUM(cl.charge_amount) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY a.bsa_id, cl.billing_period_id;
SELECT a.student_nbr, cl.charge_type FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_type = 'HOUSING' AND cl.term_cd = '202501';
SELECT a.credit_limit, COUNT(DISTINCT a.bsa_id) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_amount > a.credit_limit GROUP BY a.credit_limit;
SELECT a.student_nbr, cl.charge_date FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_date = a.last_stmt_dt;
SELECT cl.charge_type, cl.term_cd, AVG(cl.charge_amount) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY cl.charge_type, cl.term_cd;
SELECT a.bsa_id, a.student_nbr FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_type = 'TUITION' AND cl.term_cd = '202501' AND cl.waived_fg = 'N' ORDER BY a.student_nbr;
SELECT a.student_nbr, SUM(cl.charge_amount) AS spring_charges FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.term_cd = '202501' AND cl.waived_fg = 'N' GROUP BY a.student_nbr ORDER BY spring_charges DESC;
SELECT a.bsa_id, COUNT(cl.bcl_id) AS charge_count FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id GROUP BY a.bsa_id HAVING COUNT(cl.bcl_id) > 5;
SELECT a.student_nbr, cl.charge_type, cl.charge_amount FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_amount = 0;
SELECT a.acct_status, SUM(cl.charge_amount) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.waived_fg = 'N' GROUP BY a.acct_status;
SELECT a.student_nbr, cl.bcl_id, cl.upd_dt FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.upd_dt >= SYSDATE - 14;
SELECT a.bsa_id, cl.charge_type FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_type IN ('TUITION','FEES','HOUSING') AND cl.term_cd = '202501';
SELECT a.last_pmt_amt, cl.charge_amount FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE a.last_pmt_amt < cl.charge_amount AND a.acct_status = 'D';
SELECT a.student_nbr, cl.term_cd FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.due_date < SYSDATE AND cl.waived_fg = 'N' GROUP BY a.student_nbr, cl.term_cd;
SELECT COUNT(DISTINCT a.student_nbr) FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.term_cd = '202501' AND cl.charge_type = 'TUITION' AND cl.waived_fg = 'N';
SELECT a.student_nbr, cl.charge_amount, cl.charge_date FROM burs_student_account a JOIN burs_charge_line cl ON a.bsa_id = cl.bsa_id WHERE cl.charge_type = 'LATE_FEE' ORDER BY cl.charge_date DESC;

-- =============================================================================
-- O7: RESEARCH_PROJECT ↔ GRANT_TBL — HIGH AFFINITY pair concentration
-- =============================================================================
SELECT rp.project_id, rp.project_title, g.grant_nbr, g.grant_amount FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id;
SELECT rp.project_id, g.agency_name, g.grant_amount FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_status = 'ACTIVE';
SELECT rp.dept_id, SUM(g.grant_amount) AS dept_funding FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE rp.status = 'A' GROUP BY rp.dept_id;
SELECT rp.project_title, g.grant_nbr, g.start_date, g.end_date FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.end_date >= SYSDATE ORDER BY g.end_date;
SELECT rp.project_type, COUNT(g.grant_id) AS grants FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY rp.project_type;
SELECT rp.project_id, g.agency_type, g.cfda_nbr FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.agency_type = 'FEDERAL';
SELECT rp.pi_appt_id, SUM(g.grant_amount) AS pi_funding FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_status = 'ACTIVE' GROUP BY rp.pi_appt_id;
SELECT rp.project_id, rp.indirect_rate, g.indirect_amt FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.indirect_amt > 0;
SELECT g.grant_status, COUNT(DISTINCT rp.project_id) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY g.grant_status;
SELECT rp.project_title, g.grant_amount, rp.total_budget FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_amount > rp.total_budget;
SELECT rp.dept_id, COUNT(g.grant_id) AS active_grants FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_status = 'ACTIVE' GROUP BY rp.dept_id;
SELECT rp.project_id, g.award_date FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.award_date >= ADD_MONTHS(SYSDATE, -12);
SELECT rp.start_date, g.start_date AS grant_start FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.start_date <> rp.start_date;
SELECT rp.project_type, AVG(g.grant_amount) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_status = 'ACTIVE' GROUP BY rp.project_type;
SELECT rp.project_id, rp.project_title FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.cfda_nbr IS NOT NULL;
SELECT rp.pi_appt_id, COUNT(DISTINCT g.grant_id) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY rp.pi_appt_id HAVING COUNT(DISTINCT g.grant_id) > 1;
SELECT g.grant_nbr, rp.project_title, g.end_date FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.end_date BETWEEN SYSDATE AND SYSDATE + 90;
SELECT rp.project_id, g.grant_id, g.grant_amount FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_amount > 500000;
SELECT rp.status, g.grant_status FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE rp.status = 'C' AND g.grant_status = 'ACTIVE';
SELECT g.agency_name, MAX(g.grant_amount) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY g.agency_name ORDER BY MAX(g.grant_amount) DESC;
SELECT rp.project_id, g.grant_nbr FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_status = 'PENDING';
SELECT rp.dept_id, MIN(g.start_date) AS earliest_grant FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY rp.dept_id;
SELECT g.agency_type, SUM(g.grant_amount) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY g.agency_type;
SELECT rp.project_id, g.grant_id, g.grant_amount - g.indirect_amt AS direct_costs FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id;
SELECT rp.project_title, g.grant_status, g.grant_amount FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_status = 'CLOSED';
SELECT rp.project_id, COUNT(g.grant_id) AS grants_per_project FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY rp.project_id;
SELECT rp.pi_appt_id, SUM(g.indirect_amt) AS total_indirect FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_status = 'ACTIVE' GROUP BY rp.pi_appt_id;
SELECT rp.project_id, g.grant_nbr, g.upd_dt FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.upd_dt >= SYSDATE - 30;
SELECT rp.dept_id, rp.project_type, SUM(g.grant_amount) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE rp.status = 'A' GROUP BY rp.dept_id, rp.project_type;
SELECT rp.project_id, g.grant_amount, rp.total_budget, g.grant_amount/rp.total_budget AS grant_coverage FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE rp.total_budget > 0;
SELECT rp.project_title, g.grant_nbr, g.agency_name FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE rp.status = 'A' AND g.grant_status = 'ACTIVE' ORDER BY g.grant_amount DESC;
SELECT rp.project_id, g.grant_id FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_status = 'ACTIVE' AND g.end_date < SYSDATE;
SELECT rp.dept_id, MAX(g.grant_amount) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY rp.dept_id;
SELECT g.cfda_nbr, COUNT(*) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.cfda_nbr IS NOT NULL GROUP BY g.cfda_nbr;
SELECT rp.pi_appt_id, g.grant_nbr, g.start_date FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.start_date >= TO_DATE('2023-01-01', 'YYYY-MM-DD');
SELECT rp.project_id, rp.end_date, g.end_date FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE rp.end_date < g.end_date;
SELECT rp.status, SUM(g.grant_amount) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id GROUP BY rp.status;
SELECT rp.project_id, g.grant_title FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_title IS NOT NULL AND rp.project_title <> g.grant_title;
SELECT rp.project_id, g.grant_amount FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.agency_type = 'PRIVATE' AND g.grant_status = 'ACTIVE';
SELECT rp.pi_appt_id, rp.dept_id, COUNT(*) FROM research_project rp JOIN grant_tbl g ON rp.project_id = g.project_id WHERE g.grant_status = 'ACTIVE' GROUP BY rp.pi_appt_id, rp.dept_id;

-- =============================================================================
-- O8: HSG_ROOM_INVENTORY ↔ HSG_ROOM_ASSIGNMENT — HIGH AFFINITY pair concentration
-- =============================================================================
SELECT r.hsg_room_id, r.room_nbr, r.bldg_cd, a.student_id FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501';
SELECT r.bldg_cd, COUNT(a.hra_id) AS occupants FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.bldg_cd;
SELECT r.hsg_room_id, r.capacity, COUNT(a.hra_id) AS assigned FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.hsg_room_id, r.capacity;
SELECT r.room_type, r.rate_per_sem, a.student_id FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.check_in_dt IS NOT NULL;
SELECT r.bldg_cd, r.room_nbr, a.assignment_type FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' ORDER BY r.bldg_cd, r.room_nbr;
SELECT r.floor_nbr, COUNT(a.student_id) FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.floor_nbr;
SELECT r.hsg_room_id, r.room_status, a.check_out_dt FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.check_out_dt IS NOT NULL;
SELECT r.room_type, AVG(r.rate_per_sem) AS avg_rate FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.room_type;
SELECT r.gender_assn, COUNT(DISTINCT a.student_id) FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.gender_assn;
SELECT r.hsg_room_id, r.capacity - COUNT(a.hra_id) AS vacancies FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.hsg_room_id, r.capacity HAVING r.capacity - COUNT(a.hra_id) > 0;
SELECT r.bldg_cd, r.rate_per_sem, a.student_id FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' AND r.rate_per_sem > 3000;
SELECT r.hsg_room_id, a.assignment_dt FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.assignment_dt >= SYSDATE - 60;
SELECT r.room_type, COUNT(DISTINCT a.student_id) FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.room_type;
SELECT r.bldg_cd, a.student_id, a.check_in_dt FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.check_in_dt IS NULL AND a.term_cd = '202501';
SELECT r.hsg_room_id, r.amenities FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE r.amenities IS NOT NULL AND a.term_cd = '202501' GROUP BY r.hsg_room_id, r.amenities;
SELECT r.bldg_cd, MIN(a.assignment_dt) AS first_assigned FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id GROUP BY r.bldg_cd;
SELECT r.hsg_room_id, a.student_id FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE r.room_status = 'AVAILABLE' AND a.term_cd = '202501';
SELECT r.room_type, r.floor_nbr, COUNT(a.hra_id) FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.room_type, r.floor_nbr;
SELECT r.bldg_cd, SUM(r.rate_per_sem) AS revenue FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.bldg_cd;
SELECT r.hsg_room_id, a.roommate_pref FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.roommate_pref IS NOT NULL AND a.term_cd = '202501';
SELECT r.campus_cd, COUNT(DISTINCT a.student_id) FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.campus_cd;
SELECT r.hsg_room_id, COUNT(DISTINCT a.term_cd) AS terms_occupied FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id GROUP BY r.hsg_room_id;
SELECT r.room_nbr, r.bldg_cd FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202502' AND a.student_id IS NOT NULL;
SELECT r.hsg_room_id, r.capacity FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.hsg_room_id, r.capacity HAVING COUNT(a.hra_id) = r.capacity;
SELECT r.bldg_cd, r.floor_nbr, a.student_id FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE r.gender_assn = 'F' AND a.term_cd = '202501';
SELECT r.room_type, MAX(r.rate_per_sem) FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id GROUP BY r.room_type;
SELECT r.hsg_room_id, a.check_out_dt FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.check_out_dt < SYSDATE AND a.term_cd = '202501';
SELECT r.campus_cd, r.bldg_cd, COUNT(*) FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.campus_cd, r.bldg_cd;
SELECT r.hsg_room_id FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.assignment_type = 'EMERGENCY' AND a.term_cd = '202501';
SELECT r.bldg_cd, AVG(r.rate_per_sem) FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.bldg_cd ORDER BY AVG(r.rate_per_sem) DESC;
SELECT COUNT(DISTINCT r.hsg_room_id) AS occupied_rooms, COUNT(DISTINCT a.student_id) AS students FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501';
SELECT r.hsg_room_id, a.student_id, a.term_cd FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd IN ('202401','202501') AND r.room_status = 'OCCUPIED';
SELECT r.floor_nbr, r.bldg_cd, r.capacity FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.check_in_dt IS NOT NULL AND a.term_cd = '202501' GROUP BY r.floor_nbr, r.bldg_cd, r.capacity;
SELECT r.bldg_cd, SUM(r.capacity) AS total_beds, COUNT(a.hra_id) AS filled FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' GROUP BY r.bldg_cd;
SELECT r.hsg_room_id, a.upd_dt FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.upd_dt >= SYSDATE - 7 ORDER BY a.upd_dt DESC;
SELECT r.room_type, r.capacity, a.student_id FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE r.capacity = 1 AND a.term_cd = '202501';
SELECT r.bldg_cd, COUNT(DISTINCT a.student_id) FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' AND r.campus_cd = 'MAIN' GROUP BY r.bldg_cd;
SELECT r.hsg_room_id, a.student_id FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE r.room_status <> 'AVAILABLE' AND a.term_cd = '202501';
SELECT r.amenities, COUNT(DISTINCT a.student_id) FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' AND r.amenities LIKE '%PRIVATE BATH%' GROUP BY r.amenities;
SELECT r.bldg_cd, r.room_nbr, r.rate_per_sem, a.term_cd FROM hsg_room_inventory r JOIN hsg_room_assignment a ON r.hsg_room_id = a.hsg_room_id WHERE a.term_cd = '202501' ORDER BY r.rate_per_sem DESC;

-- =============================================================================
-- O9: DINING_PLAN ↔ DINING_TRANSACTION — HIGH AFFINITY pair concentration
-- =============================================================================
SELECT dp.dp_id, dp.student_id, dp.plan_type, dt.trans_type FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501';
SELECT dp.student_id, SUM(dt.flex_amt) AS total_flex FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.student_id;
SELECT dp.plan_type, COUNT(dt.dt_id) AS transactions FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.plan_type;
SELECT dp.dp_id, dp.flex_dollars, SUM(dt.flex_amt) AS used_flex FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.dp_id, dp.flex_dollars;
SELECT dp.student_id, dt.trans_type, COUNT(*) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.student_id, dt.trans_type;
SELECT dp.plan_type, AVG(dt.flex_amt) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.flex_amt > 0 GROUP BY dp.plan_type;
SELECT dp.dp_id, dt.location_id, COUNT(*) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.dp_id, dt.location_id;
SELECT dp.student_id, dp.flex_dollars - SUM(dt.flex_amt) AS remaining_flex FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.student_id, dp.flex_dollars;
SELECT dp.plan_type, SUM(dt.meal_count) AS meals_used FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.plan_type;
SELECT dp.dp_id, dt.trans_dt FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.flex_amt < 0;
SELECT dp.plan_status, COUNT(dt.dt_id) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id GROUP BY dp.plan_status;
SELECT dp.student_id, MIN(dt.trans_dt) AS first_use FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.student_id;
SELECT dp.meals_per_wk, AVG(dt.meal_count) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.meals_per_wk;
SELECT dp.dp_id, dt.balance_after FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.balance_after < 0;
SELECT dp.student_id, COUNT(DISTINCT dt.location_id) AS locations_visited FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.student_id;
SELECT dp.term_cd, SUM(dt.flex_amt) AS flex_revenue FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id GROUP BY dp.term_cd;
SELECT dp.dp_id, dp.plan_cost, COUNT(dt.dt_id) AS txn_count FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.dp_id, dp.plan_cost;
SELECT dp.plan_type, MAX(dt.trans_dt) AS last_use FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.plan_type;
SELECT dp.student_id, dt.trans_type FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.trans_type = 'SWIPE' AND dp.term_cd = '202501';
SELECT dp.plan_status, dp.term_cd, COUNT(DISTINCT dp.student_id) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id GROUP BY dp.plan_status, dp.term_cd;
SELECT dp.dp_id, dt.meal_count, dt.flex_amt FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.meal_count = 0 AND dt.flex_amt > 0;
SELECT dp.student_id, dp.start_dt, MIN(dt.trans_dt) AS first_swipe FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.student_id, dp.start_dt;
SELECT dp.plan_type, COUNT(DISTINCT dp.student_id) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.trans_dt >= ADD_MONTHS(SYSDATE, -1) GROUP BY dp.plan_type;
SELECT dp.dp_id, SUM(dt.meal_count) AS total_meals FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.dp_id;
SELECT dp.student_id, dp.end_dt, MAX(dt.trans_dt) AS last_use FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.student_id, dp.end_dt;
SELECT dp.dp_id, dt.balance_after FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.balance_after < dp.flex_dollars * 0.1 AND dp.term_cd = '202501';
SELECT dp.plan_type, dt.location_id, COUNT(*) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.plan_type, dt.location_id;
SELECT dp.student_id, dp.plan_cost FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.student_id, dp.plan_cost HAVING COUNT(dt.dt_id) = 0;
SELECT dp.dp_id, COUNT(dt.dt_id) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.dp_id HAVING COUNT(dt.dt_id) > 50;
SELECT dp.term_cd, COUNT(DISTINCT dp.student_id) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id GROUP BY dp.term_cd ORDER BY dp.term_cd;
SELECT dp.plan_type, SUM(dt.flex_amt) AS total_flex_used FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.plan_type;
SELECT dp.student_id, MAX(dt.trans_dt) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.plan_status = 'ACTIVE' GROUP BY dp.student_id;
SELECT dp.dp_id, dt.trans_type, dt.flex_amt FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.trans_type = 'REFUND';
SELECT dp.meals_per_wk, COUNT(DISTINCT dp.student_id) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.meals_per_wk;
SELECT dp.student_id, dp.plan_type FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' AND dt.flex_amt > 20 ORDER BY dt.flex_amt DESC;
SELECT dp.dp_id, dp.flex_dollars, dt.balance_after FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.balance_after = dp.flex_dollars;
SELECT dp.plan_type, AVG(dt.meal_count) FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dp.term_cd = '202501' GROUP BY dp.plan_type;
SELECT dp.student_id, dt.meal_count FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.meal_count > dp.meals_per_wk;
SELECT dp.dp_id, dt.dt_id FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id WHERE dt.trans_dt > dp.end_dt;
SELECT dp.term_cd, MIN(dt.trans_dt) AS earliest_swipe FROM dining_plan dp JOIN dining_transaction dt ON dp.dp_id = dt.dp_id GROUP BY dp.term_cd ORDER BY dp.term_cd;

-- END OF FAMILY O
-- Added 40 pure 2-table queries per HIGH target pair (O1–O9)
-- Total new queries: ~360
-- sts_loader detects "HIGH AFFINITY" in first statement of each sub-section → weight 1500

-- ============================================================
-- FAMILY P: HIGH AFFINITY CHAIN CONCENTRATION — multi-hop joins
-- Pure 3-4 table chains targeting demo-critical join paths.
-- sts_loader detects "HIGH AFFINITY" keyword → weight 1500.
-- Each sub-section boosts: (A,B), (B,C), and indirect (A,C) pairs.
-- ============================================================

-- P1: STU_MST → ENRL_REC → ACAD_EXCEPTION_WRK — HIGH AFFINITY chain concentration
-- 15 queries × weight 1500. Boosts pairs (STU_MST,ENRL_REC), (ENRL_REC,ACAD_EXCEPTION_WRK),
-- and indirect (STU_MST,ACAD_EXCEPTION_WRK). Core demo chain: "pending grade change exceptions."

SELECT s.stu_id, s.stu_lnm, e.er_id, e.er_term_cd, a.aew_stat_cd, a.aew_type_cd FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_stat_cd = 'PEND';
SELECT s.stu_id, s.stu_lnm, a.aew_type_cd, a.aew_impact_gpa FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_impact_gpa > 0;
SELECT s.stu_id, s.stu_gpa, a.aew_stat_cd, a.aew_impact_gpa FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_type_cd = 'GRD_CHNG';
SELECT e.er_term_cd, COUNT(a.aew_id) AS exception_count FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id GROUP BY e.er_term_cd;
SELECT s.stu_id, s.stu_lnm, a.aew_type_cd, a.aew_subm_dt, a.aew_dcsn_dt FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_stat_cd = 'APRV';
SELECT s.stu_id, s.stu_lvl, a.aew_type_cd, a.aew_stat_cd FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_type_cd = 'WTHDR_MED';
SELECT s.stu_id, s.stu_lnm, a.aew_dept_aprv, a.aew_dean_aprv FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_dept_aprv = 'Y' AND a.aew_dean_aprv = 'N';
SELECT a.aew_type_cd, COUNT(DISTINCT s.stu_id) AS student_count FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id GROUP BY a.aew_type_cd;
SELECT s.stu_id, s.stu_gpa, a.aew_impact_gpa, s.stu_gpa + a.aew_impact_gpa AS projected_gpa FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_stat_cd = 'PEND' AND a.aew_impact_gpa IS NOT NULL;
SELECT s.stu_id, s.dept_id, a.aew_stat_cd, a.aew_subm_dt FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_subm_dt >= ADD_MONTHS(SYSDATE, -3);
SELECT e.er_term_cd, a.aew_type_cd, COUNT(*) AS cnt FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id GROUP BY e.er_term_cd, a.aew_type_cd ORDER BY e.er_term_cd;
SELECT s.stu_id, s.stu_lnm, a.aew_type_cd FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_type_cd = 'INC_EXTND' AND a.aew_stat_cd = 'PEND';
SELECT s.stu_id, a.aew_stat_cd, a.aew_dcsn_dt FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_dcsn_dt IS NULL AND a.aew_subm_dt <= ADD_MONTHS(SYSDATE, -1);
SELECT s.stu_lvl, AVG(a.aew_impact_gpa) AS avg_gpa_impact FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_impact_gpa IS NOT NULL GROUP BY s.stu_lvl;
SELECT s.stu_id, s.stu_lnm, e.er_term_cd, a.aew_type_cd, a.aew_impact_gpa FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id WHERE a.aew_type_cd = 'LATE_DROP' AND a.aew_stat_cd IN ('PEND','APRV');

-- P2: STU_MST → STU_FA_XREF → FINANCIAL_AID_APPLICATION — HIGH AFFINITY chain concentration
-- 15 queries × weight 1500. Boosts (STU_MST,STU_FA_XREF), (STU_FA_XREF,FINANCIAL_AID_APPLICATION),
-- indirect (STU_MST,FINANCIAL_AID_APPLICATION). Demo: "honors students with unmet financial need."

SELECT s.stu_id, s.stu_lnm, x.sfx_fa_nbr, f.status, f.efc_amount FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.status = 'A';
SELECT s.stu_id, s.stu_lnm, f.aid_year, f.efc_amount FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.status = 'P';
SELECT s.stu_id, x.sfx_xref_typ, f.dependency_status, f.housing_plan FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.aid_year = 2025;
SELECT s.stu_id, s.stu_lnm, f.faa_id, f.application_date FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.efc_amount = 0;
SELECT s.stu_lvl, COUNT(DISTINCT s.stu_id) AS applicants FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.status = 'A' GROUP BY s.stu_lvl;
SELECT s.stu_id, f.aid_year, f.enrollment_level FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.status != 'D';
SELECT s.stu_id, s.stu_lnm, x.sfx_fa_nbr, f.verification_status FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.verification_status = 'SELECTED';
SELECT s.dept_id, AVG(f.efc_amount) AS avg_efc FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.status = 'A' GROUP BY s.dept_id;
SELECT s.stu_id, f.housing_plan, f.dependency_status FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.housing_plan = 'ON_CAMPUS' AND f.aid_year = 2025;
SELECT s.stu_id, s.stu_lnm, f.faa_id, f.fafsa_receipt_dt FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.fafsa_receipt_dt IS NULL AND f.status = 'P';
SELECT f.aid_year, COUNT(DISTINCT s.stu_id) AS students, SUM(f.efc_amount) AS total_efc FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id GROUP BY f.aid_year;
SELECT s.stu_id, x.sfx_eff_dt, f.application_date FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE x.sfx_xref_typ = 'PRIMARY';
SELECT s.stu_id, s.stu_lnm, f.status, f.status_date FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.status = 'D' AND f.aid_year = 2025;
SELECT s.stu_id, f.isir_transaction_nbr, f.verification_status FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id WHERE f.isir_transaction_nbr > 1;
SELECT s.stu_id, COUNT(f.faa_id) AS application_count FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id GROUP BY s.stu_id HAVING COUNT(f.faa_id) > 1;

-- P3: FACULTY_APPT → GRANT_ALLOC_WRK → GRANT_TBL (+ RESEARCH_PROJECT) — HIGH AFFINITY chain
-- 15 queries × weight 1500. Boosts (FACULTY_APPT,GRANT_ALLOC_WRK), (GRANT_ALLOC_WRK,GRANT_TBL),
-- indirect pairs. Demo: "faculty overcommitted on grants."

SELECT fa.fa_appt_id, fa.fa_rank, gaw.gaw_alloc_pct, gaw.gaw_committed_amt FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref WHERE fa.fa_status = 'A';
SELECT fa.fa_appt_id, fa.fa_fte, SUM(gaw.gaw_alloc_pct) AS total_alloc FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref GROUP BY fa.fa_appt_id, fa.fa_fte;
SELECT fa.fa_appt_id, fa.fa_research_pct, gaw.gaw_alloc_pct, g.grant_status FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref WHERE g.grant_status = 'ACTIVE';
SELECT fa.fa_appt_id, gaw.gaw_bgt_period, gaw.gaw_committed_amt, gaw.gaw_actual_amt FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref WHERE gaw.gaw_actual_amt > gaw.gaw_committed_amt;
SELECT fa.fa_dept_id, COUNT(DISTINCT fa.fa_appt_id) AS pi_count, SUM(g.grant_amount) AS total_funding FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref WHERE g.grant_status = 'ACTIVE' GROUP BY fa.fa_dept_id;
SELECT fa.fa_appt_id, fa.fa_rank, gaw.gaw_status FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref WHERE gaw.gaw_status = 'A' AND g.grant_status = 'ACTIVE';
SELECT fa.fa_appt_id, g.agency_name, g.grant_amount, gaw.gaw_alloc_pct FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref WHERE g.agency_type = 'FEDERAL';
SELECT fa.fa_appt_id, fa.fa_tenure_trk, COUNT(gaw.gaw_id) AS allocation_count FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref GROUP BY fa.fa_appt_id, fa.fa_tenure_trk;
SELECT fa.fa_appt_id, g.grant_nbr, g.end_date FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref WHERE g.end_date < ADD_MONTHS(SYSDATE, 3) AND g.grant_status = 'ACTIVE';
SELECT fa.fa_appt_id, gaw.gaw_bgt_period, SUM(gaw.gaw_committed_amt) AS period_total FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref WHERE g.grant_status = 'ACTIVE' GROUP BY fa.fa_appt_id, gaw.gaw_bgt_period;
SELECT fa.fa_appt_id, r.project_title, g.grant_amount, gaw.gaw_alloc_pct FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref JOIN research_project r ON r.project_id = g.project_id WHERE r.status = 'A';
SELECT fa.fa_appt_id, r.sponsor_type, COUNT(gaw.gaw_id) AS allocations FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref JOIN research_project r ON r.project_id = g.project_id GROUP BY fa.fa_appt_id, r.sponsor_type;
SELECT fa.fa_appt_id, fa.fa_research_pct, r.total_budget FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref JOIN research_project r ON r.project_id = g.project_id WHERE fa.fa_status = 'A' AND r.status = 'A';
SELECT fa.fa_dept_id, r.project_type, SUM(gaw.gaw_alloc_pct) AS dept_effort FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref JOIN research_project r ON r.project_id = g.project_id GROUP BY fa.fa_dept_id, r.project_type;
SELECT fa.fa_appt_id, SUM(gaw.gaw_alloc_pct) AS total_pct_effort FROM faculty_appt fa JOIN grant_alloc_wrk gaw ON gaw.gaw_facappt_key = fa.fa_appt_id JOIN grant_tbl g ON g.grant_id = gaw.gaw_grant_ref WHERE g.grant_status = 'ACTIVE' AND gaw.gaw_status = 'A' GROUP BY fa.fa_appt_id HAVING SUM(gaw.gaw_alloc_pct) > 100;

-- P4: ENRL_REC → GRD_HIST → DEGREE_AUDIT_WRK — HIGH AFFINITY chain concentration
-- 15 queries × weight 1500. Boosts (ENRL_REC,GRD_HIST), (GRD_HIST,DEGREE_AUDIT_WRK),
-- indirect (ENRL_REC,DEGREE_AUDIT_WRK). Graduation check join path.

SELECT e.er_stu_id, e.er_term_cd, gh.gh_grd_cd, d.daw_stat_cd FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id AND gh.gh_term_cd = e.er_term_cd JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE d.daw_stat_cd = 'ELIGIBLE';
SELECT e.er_stu_id, SUM(gh.gh_crd_ernd) AS earned, d.daw_hrs_req FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id GROUP BY e.er_stu_id, d.daw_hrs_req;
SELECT e.er_stu_id, e.er_term_cd, gh.gh_grd_pts, d.daw_gpa_req, d.daw_gpa_act FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id AND gh.gh_term_cd = e.er_term_cd JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE d.daw_gpa_act < d.daw_gpa_req;
SELECT e.er_stu_id, d.daw_degree_cd, d.daw_hrs_comp, d.daw_hrs_req FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE d.daw_hrs_comp >= d.daw_hrs_req AND d.daw_stat_cd != 'ELIGIBLE';
SELECT e.er_stu_id, gh.gh_term_cd, COUNT(gh.gh_id) AS courses_taken, d.daw_stat_cd FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id GROUP BY e.er_stu_id, gh.gh_term_cd, d.daw_stat_cd;
SELECT d.daw_stu_id, d.daw_term_cd, d.daw_hold_cnt, COUNT(e.er_id) AS active_enrollments FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE d.daw_hold_cnt > 0 GROUP BY d.daw_stu_id, d.daw_term_cd, d.daw_hold_cnt;
SELECT e.er_stu_id, gh.gh_repeat_fg, gh.gh_crs_nbr, d.daw_gpa_act FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE gh.gh_repeat_fg = 'Y';
SELECT e.er_stu_id, d.daw_res_hrs, SUM(gh.gh_crd_ernd) AS total_earned FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id GROUP BY e.er_stu_id, d.daw_res_hrs HAVING SUM(gh.gh_crd_ernd) >= d.daw_res_hrs;
SELECT e.er_stu_id, d.daw_run_dt, d.daw_stat_cd FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE d.daw_run_dt < ADD_MONTHS(SYSDATE, -6) AND d.daw_stat_cd = 'PENDING';
SELECT d.daw_degree_cd, AVG(d.daw_gpa_act) AS avg_grad_gpa FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE d.daw_stat_cd = 'ELIGIBLE' GROUP BY d.daw_degree_cd;
SELECT e.er_stu_id, e.er_term_cd, gh.gh_grd_cd FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id AND gh.gh_term_cd = e.er_term_cd JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE gh.gh_grd_cd = 'W' AND d.daw_stat_cd = 'ELIGIBLE';
SELECT e.er_stu_id, d.daw_notes FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE d.daw_notes IS NOT NULL AND d.daw_stat_cd = 'INELIGIBLE';
SELECT e.er_stu_id, d.daw_term_cd, d.daw_hrs_comp, d.daw_hrs_req, (d.daw_hrs_req - d.daw_hrs_comp) AS hrs_remaining FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE d.daw_hrs_comp < d.daw_hrs_req;
SELECT d.daw_stat_cd, COUNT(DISTINCT e.er_stu_id) AS student_count FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id WHERE d.daw_term_cd = '202501' GROUP BY d.daw_stat_cd;
SELECT e.er_stu_id, gh.gh_term_cd, gh.gh_grd_pts, d.daw_gpa_act FROM enrl_rec e JOIN grd_hist gh ON gh.gh_stu_id = e.er_stu_id AND gh.gh_term_cd = e.er_term_cd JOIN degree_audit_wrk d ON d.daw_stu_id = e.er_stu_id ORDER BY ABS(gh.gh_grd_pts - d.daw_gpa_act) DESC;

-- P5: STU_MST → ENRL_REC → ACAD_EXCEPTION_WRK → BURS_STUDENT_ACCOUNT — HIGH AFFINITY 4-hop
-- 10 queries × weight 1500. Full exception→bursar chain. Boosts all 6 pairwise combinations
-- including (ACAD_EXCEPTION_WRK, BURS_STUDENT_ACCOUNT). Demo: "approved exception, bursar hold still active."

SELECT s.stu_id, s.stu_lnm, a.aew_stat_cd, bsa.acct_status, bsa.current_balance FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id JOIN burs_student_account bsa ON bsa.student_nbr = s.stu_id WHERE a.aew_stat_cd = 'APRV' AND bsa.acct_status = 'D';
SELECT s.stu_id, a.aew_type_cd, a.aew_impact_gpa, bsa.current_balance FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id JOIN burs_student_account bsa ON bsa.student_nbr = s.stu_id WHERE a.aew_stat_cd = 'APRV' AND bsa.past_due_amt > 0;
SELECT s.stu_id, e.er_term_cd, a.aew_type_cd, bsa.acct_status FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id JOIN burs_student_account bsa ON bsa.student_nbr = s.stu_id WHERE a.aew_stat_cd = 'PEND' AND bsa.current_balance > 0;
SELECT s.stu_id, a.aew_stat_cd, bsa.payment_plan_fg, bsa.past_due_amt FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id JOIN burs_student_account bsa ON bsa.student_nbr = s.stu_id WHERE a.aew_type_cd = 'WTHDR_MED';
SELECT COUNT(DISTINCT s.stu_id) AS students_with_exception_and_balance FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id JOIN burs_student_account bsa ON bsa.student_nbr = s.stu_id WHERE a.aew_stat_cd = 'APRV' AND bsa.current_balance > 500;
SELECT s.stu_id, a.aew_dcsn_dt, bsa.last_pmt_dt, bsa.last_pmt_amt FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id JOIN burs_student_account bsa ON bsa.student_nbr = s.stu_id WHERE a.aew_stat_cd = 'APRV' AND bsa.last_pmt_dt IS NULL;
SELECT bsa.acct_status, a.aew_type_cd, COUNT(*) AS case_count FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id JOIN burs_student_account bsa ON bsa.student_nbr = s.stu_id GROUP BY bsa.acct_status, a.aew_type_cd;
SELECT s.stu_id, a.aew_impact_gpa, bsa.current_balance FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id JOIN burs_student_account bsa ON bsa.student_nbr = s.stu_id WHERE a.aew_impact_gpa > 0 AND a.aew_stat_cd = 'PEND';
SELECT s.stu_id, a.aew_subm_dt, bsa.acct_open_dt, bsa.current_balance FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id JOIN burs_student_account bsa ON bsa.student_nbr = s.stu_id WHERE a.aew_type_cd = 'GRD_CHNG' AND bsa.acct_status != 'S';
SELECT s.stu_id, s.stu_lnm, e.er_term_cd, a.aew_stat_cd, bsa.past_due_amt FROM stu_mst s JOIN enrl_rec e ON e.er_stu_id = s.stu_id JOIN acad_exception_wrk a ON a.aew_enrl_key = e.er_id JOIN burs_student_account bsa ON bsa.student_nbr = s.stu_id WHERE a.aew_dean_aprv = 'Y' ORDER BY bsa.past_due_amt DESC;

-- P6: STU_MST → STU_FA_XREF → FINANCIAL_AID_APPLICATION → NEED_ANALYSIS_RESULT — HIGH AFFINITY 4-hop
-- 10 queries × weight 1500. Full FA chain. Boosts all pairs including
-- (FINANCIAL_AID_APPLICATION,NEED_ANALYSIS_RESULT), (STU_FA_XREF,NEED_ANALYSIS_RESULT).
-- Demo: "students with unmet financial need."

SELECT s.stu_id, s.stu_lnm, f.efc_amount, n.unmet_need_federal FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id JOIN need_analysis_result n ON n.faa_id = f.faa_id WHERE n.unmet_need_federal > 0 AND f.status = 'A';
SELECT s.stu_id, f.aid_year, n.pell_eligible, n.efc_federal FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id JOIN need_analysis_result n ON n.faa_id = f.faa_id WHERE n.pell_eligible = 'Y';
SELECT s.stu_lvl, AVG(n.unmet_need_inst) AS avg_unmet_need FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id JOIN need_analysis_result n ON n.faa_id = f.faa_id WHERE f.status = 'A' GROUP BY s.stu_lvl;
SELECT s.stu_id, n.coa_on_campus, n.coa_off_campus, f.housing_plan FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id JOIN need_analysis_result n ON n.faa_id = f.faa_id WHERE f.housing_plan = 'ON_CAMPUS';
SELECT s.stu_id, x.sfx_fa_nbr, n.auto_zero_efc, n.simplified_needs FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id JOIN need_analysis_result n ON n.faa_id = f.faa_id WHERE n.auto_zero_efc = 'Y';
SELECT f.aid_year, COUNT(n.nar_id) AS analyses_run, AVG(n.efc_institutional) AS avg_inst_efc FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id JOIN need_analysis_result n ON n.faa_id = f.faa_id GROUP BY f.aid_year;
SELECT s.stu_id, s.stu_lnm, n.unmet_need_federal, n.unmet_need_inst FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id JOIN need_analysis_result n ON n.faa_id = f.faa_id WHERE n.unmet_need_federal > n.unmet_need_inst AND f.status = 'A';
SELECT s.stu_id, f.dependency_status, n.efc_federal FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id JOIN need_analysis_result n ON n.faa_id = f.faa_id WHERE f.dependency_status = 'INDEPENDENT' AND n.efc_federal = 0;
SELECT s.stu_id, x.sfx_xref_typ, f.verification_status, n.pell_eligible FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id JOIN need_analysis_result n ON n.faa_id = f.faa_id WHERE f.verification_status = 'SELECTED' AND n.pell_eligible = 'Y';
SELECT s.stu_id, n.nar_run_date, f.fafsa_receipt_dt, n.efc_federal FROM stu_mst s JOIN stu_fa_xref x ON x.sfx_stu_id = s.stu_id JOIN financial_aid_application f ON f.fa_stu_key = s.stu_id JOIN need_analysis_result n ON n.faa_id = f.faa_id WHERE f.aid_year = 2025 ORDER BY n.unmet_need_federal DESC;

-- END OF FAMILY P
-- Added 80 multi-hop chain queries (P1-P6) at HIGH AFFINITY weight 1500
-- P1-P4: 15 queries each (3-table chains)
-- P5-P6: 10 queries each (4-table chains)
