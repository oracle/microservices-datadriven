# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at http://oss.oracle.com/licenses/upl.

"""
Westfield University — deterministic Faker seeder.
seed=42, ~8k students, ~1k courses, ~35k enrollments, ~2k exception rows,
~800 FA applications, ~500 grant rows, housing + dining, research.

Insert order respects logical FK dependencies (no actual FKs declared).
"""
from __future__ import annotations

import random
from datetime import date, timedelta
from typing import Any

from faker import Faker
from rich.console import Console
from rich.progress import track

from src.db.connection import get_connection

console = Console()
fake = Faker()
Faker.seed(42)
random.seed(42)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

N_STUDENTS    = 8_000
N_DEPARTMENTS = 24
N_INSTRUCTORS = 280
N_ROOMS       = 120        # classroom rooms (ROOM_INVT — scheduling)
N_HSG_ROOMS   = 800        # residential rooms (HSG_ROOM_INVENTORY)
N_COURSES     = 420
N_TERMS       = 8          # 8 semesters of history (2021–2025)
N_EMPLOYERS   = 60

TERM_CODES = ["202101","202108","202201","202208","202301","202308","202401","202501"]
CURRENT_TERM = "202501"
CURRENT_AID_YEAR = 2025

DEPT_NAMES = [
    ("MATH",   "Mathematics"),        ("CS",     "Computer Science"),
    ("ENG",    "English"),            ("HIST",   "History"),
    ("BIOL",   "Biology"),            ("CHEM",   "Chemistry"),
    ("PHYS",   "Physics"),            ("PSYC",   "Psychology"),
    ("SOC",    "Sociology"),          ("ECON",   "Economics"),
    ("BUS",    "Business Admin"),     ("ACCT",   "Accounting"),
    ("NURS",   "Nursing"),            ("EDUC",   "Education"),
    ("POLS",   "Political Science"),  ("PHIL",   "Philosophy"),
    ("ART",    "Fine Arts"),          ("MUS",    "Music"),
    ("COMM",   "Communications"),     ("KINE",   "Kinesiology"),
    ("ENVS",   "Environmental Sci"),  ("ANTH",   "Anthropology"),
    ("FREN",   "French"),             ("SPAN",   "Spanish"),
]

INSTR_RANKS = ["LECTURER", "ASST_PROF", "ASSOC_PROF", "FULL_PROF", "DISTINGUISHED"]
RANK_WEIGHTS = [0.25, 0.30, 0.25, 0.15, 0.05]

STUDENT_LEVELS = ["FRESHMAN", "SOPHOMORE", "JUNIOR", "SENIOR", "GRAD"]
LEVEL_WEIGHTS  = [0.22, 0.22, 0.22, 0.22, 0.12]

AID_TYPES = [
    "PELL", "SUBSIDIZED", "UNSUBSIDIZED", "INSTITUTIONAL",
    "MERIT_SCHOLARSHIP", "NEED_SCHOLARSHIP", "WORK_STUDY",
]

GRANT_AGENCIES = [
    ("NSF",  "National Science Foundation", "FEDERAL"),
    ("NIH",  "National Institutes of Health", "FEDERAL"),
    ("DOE",  "Department of Energy", "FEDERAL"),
    ("NEH",  "National Endowment for Humanities", "FEDERAL"),
    ("WF Foundation", "Westfield Alumni Foundation", "PRIVATE"),
    ("State Research Council", "State Research Council", "STATE"),
    ("Industry Partner Corp", "Industry Partner Corp", "INDUSTRY"),
]

EXCEPTION_TYPES = ["WTHDR_MED", "WTHDR_PERS", "LATE_DROP", "GRD_CHNG", "INC_EXTND"]
EXCEPTION_TYPE_WEIGHTS = [0.30, 0.20, 0.20, 0.20, 0.10]

EXCEPTION_STATUSES = ["PEND", "APRV", "DENY", "WTHDR"]
EXCEPTION_STATUS_WEIGHTS = [0.35, 0.40, 0.20, 0.05]

APPEAL_CODES = ["FIN_HARD", "MED_EMRG", "SVCE_ERR", "SCHL_ERR"]
APPEAL_CODE_WEIGHTS = [0.30, 0.35, 0.20, 0.15]

BLDG_CODES = ["NORTH", "SOUTH", "EAST", "WEST", "CENTER", "ANNEX"]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _batch_insert(conn, sql: str, rows: list[tuple], batch_size: int = 500) -> None:
    with conn.cursor() as cur:
        for i in range(0, len(rows), batch_size):
            cur.executemany(sql, rows[i:i + batch_size])
    conn.commit()


def _table_empty(conn, table: str) -> bool:
    with conn.cursor() as cur:
        cur.execute(f"SELECT COUNT(*) FROM {table} FETCH FIRST 1 ROWS ONLY")
        return cur.fetchone()[0] == 0


def _rand_date(start: date, end: date) -> date:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, max(delta, 0)))


# ---------------------------------------------------------------------------
# Seeding functions — each returns list of generated IDs for FK references
# ---------------------------------------------------------------------------

def _seed_departments(conn) -> list[int]:
    if not _table_empty(conn, "dept_tbl"):
        with conn.cursor() as cur:
            cur.execute("SELECT dept_id FROM dept_tbl ORDER BY dept_id")
            return [r[0] for r in cur.fetchall()]

    rows = []
    dept_ids = []
    for i, (cd, nm) in enumerate(DEPT_NAMES, start=10):
        dept_id = i * 10
        dept_ids.append(dept_id)
        rows.append((dept_id, cd, nm, i // 8 + 1, None,
                     f"{cd.lower()}@westfield.edu", f"555-{i:04d}",
                     random.choice(["MAIN", "NORTH", "SOUTH"]),
                     "A", "ACADEMIC"))

    sql = """INSERT INTO dept_tbl
             (dept_id, dept_cd, dept_nm, coll_id, dept_head_id, dept_email,
              dept_ph, dept_loc, dept_stat, dept_type)
             VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10)"""
    _batch_insert(conn, sql, rows)
    console.print(f"  Inserted {len(rows)} departments")
    return dept_ids


def _seed_instructors(conn, dept_ids: list[int]) -> list[int]:
    if not _table_empty(conn, "instr_tbl"):
        with conn.cursor() as cur:
            cur.execute("SELECT instr_id FROM instr_tbl ORDER BY instr_id")
            return [r[0] for r in cur.fetchall()]

    rows = []
    instr_ids = []
    for i in range(1, N_INSTRUCTORS + 1):
        instr_id = 1000 + i
        instr_ids.append(instr_id)
        rank = random.choices(INSTR_RANKS, RANK_WEIGHTS)[0]
        dept_id = random.choice(dept_ids)
        rows.append((
            instr_id,
            fake.last_name(), fake.first_name(),
            dept_id,
            f"{fake.user_name()}@westfield.edu",
            rank,
            "Y" if rank in ("ASSOC_PROF", "FULL_PROF", "DISTINGUISHED") else "N",
            "A",
            _rand_date(date(1990, 1, 1), date(2020, 1, 1)),
        ))

    sql = """INSERT INTO instr_tbl
             (instr_id, instr_lnm, instr_fnm, dept_id, instr_email,
              instr_rank, instr_ten_fg, instr_stat, hire_dt)
             VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9)"""
    _batch_insert(conn, sql, rows)

    # Update dept_head_id for each dept (assign a FULL_PROF)
    senior = [r[0] for r in rows if r[6] == "Y"]
    if senior:
        with conn.cursor() as cur:
            for dept_id in dept_ids:
                cur.execute("UPDATE dept_tbl SET dept_head_id = :1 WHERE dept_id = :2",
                            [random.choice(senior), dept_id])
        conn.commit()

    console.print(f"  Inserted {len(rows)} instructors")
    return instr_ids


def _seed_rooms(conn) -> list[int]:
    """Classroom rooms for ROOM_INVT (scheduling, not residential)."""
    if not _table_empty(conn, "room_invt"):
        with conn.cursor() as cur:
            cur.execute("SELECT room_id FROM room_invt ORDER BY room_id")
            return [r[0] for r in cur.fetchall()]

    rows = []
    room_ids = []
    room_types = ["LECTURE", "LAB", "SEMINAR", "STUDIO"]
    for i in range(1, N_ROOMS + 1):
        room_id = 100 + i
        room_ids.append(room_id)
        bldg = random.choice(BLDG_CODES[:4])
        rtype = random.choices(room_types, [0.5, 0.2, 0.2, 0.1])[0]
        cap = random.choice([20, 30, 40, 60, 80, 120, 200])
        rows.append((room_id, f"{bldg}-{i:03d}", bldg, cap, rtype,
                     "PROJECTOR,WHITEBOARD", "MAIN", "A"))

    sql = """INSERT INTO room_invt
             (room_id, room_nbr, bldg_cd, room_cap, room_typ,
              room_feat, campus_cd, room_stat)
             VALUES (:1,:2,:3,:4,:5,:6,:7,:8)"""
    _batch_insert(conn, sql, rows)
    console.print(f"  Inserted {len(rows)} classroom rooms")
    return room_ids


def _seed_terms(conn) -> None:
    if not _table_empty(conn, "term_tbl"):
        return

    rows = []
    for tc in TERM_CODES:
        yr = int(tc[:4])
        sem = tc[4:]
        if sem == "01":  # Spring
            start = date(yr, 1, 15)
            end = date(yr, 5, 15)
            desc = f"Spring {yr}"
        else:            # Fall
            start = date(yr, 8, 25)
            end = date(yr, 12, 20)
            desc = f"Fall {yr}"
        rows.append((
            tc, desc, start, end,
            start - timedelta(weeks=4),  # reg_start
            start - timedelta(weeks=1),  # reg_end
            start + timedelta(weeks=2),  # add_drop_end
            start + timedelta(weeks=8),  # wthdr_end
            end + timedelta(weeks=2),    # grade_due
            "SEMESTER", yr,
        ))

    sql = """INSERT INTO term_tbl
             (term_cd, term_desc, term_start, term_end, reg_start, reg_end,
              add_drop_end, wthdr_end, grade_due, term_type, cal_yr)
             VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11)"""
    _batch_insert(conn, sql, rows)
    console.print(f"  Inserted {len(rows)} terms")


def _seed_students(conn, dept_ids: list[int]) -> list[int]:
    if not _table_empty(conn, "stu_mst"):
        with conn.cursor() as cur:
            cur.execute("SELECT stu_id FROM stu_mst ORDER BY stu_id")
            return [r[0] for r in cur.fetchall()]

    rows = []
    stu_ids = []
    for i in range(N_STUDENTS):
        stu_id = 100000 + i
        stu_ids.append(stu_id)
        lvl = random.choices(STUDENT_LEVELS, LEVEL_WEIGHTS)[0]
        stat = random.choices(["A", "A", "A", "A", "A", "I", "W", "G"],
                              [0.70, 0.70, 0.70, 0.70, 0.70, 0.05, 0.03, 0.02])[0]
        adm_dt = _rand_date(date(2018, 8, 1), date(2024, 8, 1))
        gpa = round(random.uniform(1.5, 4.0), 3)
        rows.append((
            stu_id,
            fake.last_name(), fake.first_name(),
            fake.first_name() if random.random() < 0.3 else None,
            fake.date_of_birth(minimum_age=17, maximum_age=35),
            None,  # ssn — not seeded
            fake.street_address(), None,
            fake.city(), fake.state_abbr(), fake.zipcode(),
            f"stu{stu_id}@westfield.edu",
            fake.phone_number()[:20],
            stat, lvl,
            random.choice(["F", "T"]),  # student type
            adm_dt,
            adm_dt + timedelta(days=random.randint(730, 1825)),  # exp_grad
            random.choice(dept_ids),
            gpa,
            round(random.uniform(0, 120), 1),  # hrs_att
            round(random.uniform(0, 120), 1),  # hrs_ernd
            "Y" if gpa >= 3.7 and random.random() < 0.3 else "N",
            "R" if random.random() < 0.6 else "N",  # residency
            "Y" if random.random() < 0.08 else "N",  # international
        ))

    sql = """INSERT INTO stu_mst
             (stu_id, stu_lnm, stu_fnm, stu_mnm, stu_dob, stu_ssn,
              stu_addr1, stu_addr2, stu_city, stu_st, stu_zip, stu_email,
              stu_ph, stu_stat_cd, stu_lvl, stu_typ, stu_adm_dt, stu_exp_grad,
              dept_id, stu_gpa, stu_hrs_att, stu_hrs_ernd,
              stu_honors, stu_resid, stu_intl)
             VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,
                     :17,:18,:19,:20,:21,:22,:23,:24,:25)"""
    _batch_insert(conn, sql, rows, batch_size=500)
    console.print(f"  Inserted {len(rows)} students")
    return stu_ids


def _seed_courses(conn, dept_ids: list[int]) -> list[str]:
    if not _table_empty(conn, "crs_cat"):
        with conn.cursor() as cur:
            cur.execute("SELECT crs_nbr FROM crs_cat ORDER BY crs_nbr")
            return [r[0] for r in cur.fetchall()]

    rows = []
    crs_nbrs = []
    seen_nbrs: set[str] = set()
    for i, (dept_cd, _) in enumerate(DEPT_NAMES):
        n_courses = random.randint(12, 22)
        for j in range(n_courses):
            lvl = random.choice([100, 200, 300, 400, 500])
            crs_nbr = f"{dept_cd}{lvl + random.randint(0,9):03d}"
            offset = 0
            while crs_nbr in seen_nbrs:
                offset += 1
                crs_nbr = f"{dept_cd}{lvl + offset:03d}"
            seen_nbrs.add(crs_nbr)
            crs_nbrs.append(crs_nbr)
            dept_id = [d for (cd, _) in DEPT_NAMES for d in dept_ids
                       if cd == dept_cd]
            dept_id = (i + 1) * 10
            rows.append((
                crs_nbr,
                f"{dept_cd} {lvl + j:03d}: {fake.catch_phrase()[:80]}",
                fake.paragraph(nb_sentences=2)[:500],
                random.choice([1.0, 2.0, 3.0, 3.0, 3.0, 4.0]),
                dept_id,
                dept_id,  # owner_dept_id (same unless cross-listed)
                "UNDERGRADUATE" if lvl < 500 else "GRADUATE",
                "A",
                "LECTURE",
                TERM_CODES[0],
                None,
            ))

    sql = """INSERT INTO crs_cat
             (crs_nbr, crs_title, crs_desc, crs_crd, dept_id, owner_dept_id,
              crs_lvl, crs_stat, crs_typ, crs_eff_term, crs_exp_term)
             VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11)"""
    _batch_insert(conn, sql, rows)
    console.print(f"  Inserted {len(rows)} courses")
    return crs_nbrs


def _seed_sections(conn, crs_nbrs: list[str], instr_ids: list[int],
                   room_ids: list[int], dept_ids: list[int]) -> list[int]:
    if not _table_empty(conn, "crs_sect"):
        with conn.cursor() as cur:
            cur.execute("SELECT sect_id FROM crs_sect ORDER BY sect_id")
            return [r[0] for r in cur.fetchall()]

    rows = []
    sect_ids = []
    sect_id = 10000
    meet_days_opts = ["MWF", "TR", "MW", "MWF", "TR", "F"]
    deliv_modes = ["IN_PERSON", "IN_PERSON", "IN_PERSON", "HYBRID", "ONLINE"]

    for term_cd in TERM_CODES:
        # ~60 sections per term from a rotating subset of courses
        active_courses = random.sample(crs_nbrs, min(80, len(crs_nbrs)))
        for crs_nbr in active_courses:
            if random.random() < 0.3:
                continue  # not offered every term
            sect_id += 1
            sect_ids.append(sect_id)
            max_enrl = random.choice([20, 25, 30, 35, 40, 60, 80])
            cur_enrl = random.randint(0, max_enrl)
            waitlist = random.randint(0, 5) if cur_enrl >= max_enrl else 0
            hour = random.choice([8, 9, 10, 11, 13, 14, 15, 16])
            rows.append((
                sect_id,
                crs_nbr,
                term_cd,
                f"{random.randint(1,9):02d}",
                random.choice(instr_ids),
                random.choice(room_ids),
                random.choice(dept_ids),
                max_enrl, cur_enrl, waitlist,
                random.choice(meet_days_opts),
                f"{hour:02d}:00", f"{hour+1:02d}:00",
                random.choice(deliv_modes),
                "A",
            ))

    sql = """INSERT INTO crs_sect
             (sect_id, crs_nbr, term_cd, sect_nbr, instr_id, room_id, dept_id,
              max_enrl, cur_enrl, waitlist_cnt, meet_days, meet_start, meet_end,
              deliv_mode, sect_stat)
             VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15)"""
    _batch_insert(conn, sql, rows, batch_size=300)
    console.print(f"  Inserted {len(rows)} course sections")
    return sect_ids


def _seed_enrollments(conn, stu_ids: list[int], sect_ids: list[int]) -> list[int]:
    """~35k enrollments across 8 terms."""
    if not _table_empty(conn, "enrl_rec"):
        with conn.cursor() as cur:
            cur.execute("SELECT er_id FROM enrl_rec ORDER BY er_id")
            return [r[0] for r in cur.fetchall()]

    # Build term→section map
    with conn.cursor() as cur:
        cur.execute("SELECT sect_id, term_cd FROM crs_sect ORDER BY sect_id")
        sect_term = {r[0]: r[1] for r in cur.fetchall()}

    rows = []
    er_id = 1_000_000
    enrl_ids = []
    grades = ["A","A","A-","B+","B","B","B-","C+","C","C","C-","D","F","W","I"]
    grade_pts = {"A":4.0,"A-":3.7,"B+":3.3,"B":3.0,"B-":2.7,"C+":2.3,"C":2.0,"C-":1.7,"D":1.0,"F":0.0,"W":0.0,"I":0.0}
    statuses = ["R","R","R","R","R","W","D"]
    status_w = [0.80, 0.80, 0.80, 0.80, 0.80, 0.08, 0.05]

    for stu_id in random.sample(stu_ids, min(6000, len(stu_ids))):
        n_enrl = random.randint(3, 8)
        chosen_sects = random.sample(sect_ids, min(n_enrl, len(sect_ids)))
        for sect_id in chosen_sects:
            term_cd = sect_term.get(sect_id, TERM_CODES[0])
            er_id += 1
            enrl_ids.append(er_id)
            stat = random.choices(statuses, status_w)[0]
            grd_cd = random.choice(grades) if stat in ("R","D") else None
            grd_pts_val = grade_pts.get(grd_cd, 0.0) if grd_cd else None
            crd = random.choice([1.0, 2.0, 3.0, 3.0, 4.0])
            enrl_dt = _rand_date(date(2021, 1, 1), date(2025, 1, 15))
            rows.append((
                er_id, stu_id, sect_id, term_cd, stat,
                crd, crd if grd_cd and grd_cd not in ("W","I","F") else 0.0,
                grd_cd, grd_pts_val,
                enrl_dt, None if stat != "D" else enrl_dt + timedelta(weeks=4),
                None, None, "N" if random.random() > 0.4 else "Y",
            ))

    sql = """INSERT INTO enrl_rec
             (er_id, er_stu_id, er_sect_id, er_term_cd, er_stat,
              er_crd_att, er_crd_ernd, er_grd_cd, er_grd_pts,
              er_enrl_dt, er_drop_dt, er_mid_grd, er_att_pct, er_fin_aid_fg)
             VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14)"""
    _batch_insert(conn, sql, rows, batch_size=500)
    console.print(f"  Inserted {len(rows)} enrollments")
    return enrl_ids


def _seed_grade_history(conn, enrl_ids: list[int]) -> None:
    """Post final grades for completed terms from enrollment records."""
    if not _table_empty(conn, "grd_hist"):
        return

    with conn.cursor() as cur:
        cur.execute("""
            SELECT e.er_id, e.er_stu_id, e.er_sect_id, e.er_term_cd,
                   s.crs_nbr, e.er_grd_cd, e.er_grd_pts, e.er_crd_att, s.instr_id
            FROM enrl_rec e JOIN crs_sect s ON e.er_sect_id = s.sect_id
            WHERE e.er_grd_cd IS NOT NULL AND e.er_term_cd < :1
        """, [CURRENT_TERM])
        rows_raw = cur.fetchall()

    rows = []
    for gh_id, (er_id, stu_id, sect_id, term_cd, crs_nbr, grd_cd, grd_pts, crd, instr_id) \
            in enumerate(rows_raw, start=1_000_000):
        rows.append((
            gh_id, stu_id, sect_id, term_cd, crs_nbr,
            grd_cd, grd_pts, crd,
            crd if grd_cd not in ("W","I","F") else 0.0,
            "N", _rand_date(date(2021,5,1), date(2025,5,1)), instr_id,
        ))

    sql = """INSERT INTO grd_hist
             (gh_id, gh_stu_id, gh_sect_id, gh_term_cd, gh_crs_nbr,
              gh_grd_cd, gh_grd_pts, gh_crd_att, gh_crd_ernd,
              gh_repeat_fg, gh_post_dt, gh_instr_id)
             VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12)"""
    _batch_insert(conn, sql, rows, batch_size=500)
    console.print(f"  Inserted {len(rows)} grade history rows")


def _seed_financial_aid(conn, stu_ids: list[int]) -> list[int]:
    """~800 FA applications with awards, need analysis, Pell eligibility."""
    if not _table_empty(conn, "financial_aid_application"):
        with conn.cursor() as cur:
            cur.execute("SELECT faa_id FROM financial_aid_application ORDER BY faa_id")
            return [r[0] for r in cur.fetchall()]

    fa_stu_sample = random.sample(stu_ids, 800)
    faa_rows = []
    faa_ids = []
    xref_rows = []
    award_rows = []
    nar_rows = []
    pell_rows = []

    for faa_id, stu_id in enumerate(fa_stu_sample, start=1):
        fa_stu_key = stu_id  # same value, used on both sides of STU_FA_XREF
        sfx_fa_nbr = f"FA{faa_id:07d}"
        efc = round(random.uniform(0, 25000), 2)
        coa = round(random.uniform(18000, 35000), 2)
        status = random.choices(["A","P","D"], [0.65, 0.25, 0.10])[0]
        dep_status = random.choice(["DEPENDENT","INDEPENDENT"])

        faa_ids.append(faa_id)
        faa_rows.append((
            faa_id, fa_stu_key, CURRENT_AID_YEAR,
            _rand_date(date(2024, 10, 1), date(2025, 1, 15)),
            random.choice(["VERIFIED","SELECTED","NOT_SELECTED"]),
            efc, status, _rand_date(date(2024,11,1), date(2025,3,1)),
            dep_status, random.choice(["ON_CAMPUS","OFF_CAMPUS","WITH_PARENT"]),
            "FULL_TIME", _rand_date(date(2024,10,1), date(2024,12,1)),
            random.randint(1,4),
        ))

        # STU_FA_XREF — the critical crosswalk bridge
        xref_rows.append((
            faa_id, stu_id, sfx_fa_nbr,
            date(2024, 10, 1), None, "PRIMARY", date(2024, 10, 1),
        ))

        # Need analysis
        nar_rows.append((
            faa_id, faa_id, date(2024, 11, 1),
            efc, efc * 0.9, coa, coa * 0.85,
            max(0, coa - efc), max(0, coa * 0.9 - efc * 0.9),
            "Y" if efc < 6500 else "N",
            "Y" if efc == 0 else "N",
            "N",
        ))

        # Pell eligibility if EFC < 6500
        if efc < 6500:
            pell_amt = round(min(7395, max(0, 7395 - efc * 0.5)), 2)
            pell_rows.append((faa_id, faa_id, CURRENT_AID_YEAR,
                              round(random.uniform(0, 4.5), 3), 6.0,
                              pell_amt, "FULL_TIME", None))

        # Awards
        if status == "A":
            n_awards = random.randint(1, 4)
            award_types = random.sample(AID_TYPES, n_awards)
            for awt in award_types:
                amt = round(random.uniform(500, 8000), 2)
                award_rows.append((
                    len(award_rows) + 1, faa_id, CURRENT_AID_YEAR,
                    awt, "FEDERAL" if awt in ("PELL","SUBSIDIZED","UNSUBSIDIZED") else "INSTITUTIONAL",
                    amt, amt, amt * 0.9,
                    "DISBURSED", date(2025,1,15), date(2025,1,20), date(2025,2,1), None,
                ))

    _batch_insert(conn, """INSERT INTO financial_aid_application
        (faa_id, fa_stu_key, aid_year, application_date, verification_status,
         efc_amount, status, status_date, dependency_status, housing_plan,
         enrollment_level, fafsa_receipt_dt, isir_transaction_nbr)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13)""", faa_rows)

    _batch_insert(conn, """INSERT INTO stu_fa_xref
        (sfx_id, sfx_stu_id, sfx_fa_nbr, sfx_eff_dt, sfx_exp_dt, sfx_xref_typ, sfx_cre_dt)
        VALUES (:1,:2,:3,:4,:5,:6,:7)""", xref_rows)

    _batch_insert(conn, """INSERT INTO need_analysis_result
        (nar_id, faa_id, nar_run_date, efc_federal, efc_institutional,
         coa_on_campus, coa_off_campus, unmet_need_federal, unmet_need_inst,
         pell_eligible, auto_zero_efc, simplified_needs)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12)""", nar_rows)

    if pell_rows:
        _batch_insert(conn, """INSERT INTO pell_eligibility_tbl
            (pell_id, faa_id, aid_year, lifetime_units, max_lifetime_units,
             pell_grant_amount, enrollment_intensity, disbursement_schedule)
            VALUES (:1,:2,:3,:4,:5,:6,:7,:8)""", pell_rows)

    if award_rows:
        _batch_insert(conn, """INSERT INTO fa_award_history
            (award_id, faa_id, aid_year, award_type, fund_source,
             offered_amount, accepted_amount, disbursed_amount, award_status,
             offer_date, accept_date, disb_date, cancel_date)
            VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13)""", award_rows)

    console.print(f"  Inserted {len(faa_rows)} FA applications, {len(xref_rows)} XREF rows, {len(award_rows)} awards")
    return faa_ids


def _seed_bursar(conn, stu_ids: list[int]) -> None:
    """Student accounts, charges, payments, holds, and tuition appeals."""
    if not _table_empty(conn, "burs_student_account"):
        return

    hold_codes = [
        ("FIN001", "Unpaid Balance", "FINANCIAL", "Y", "N", "N", "N"),
        ("FIN002", "Returned Check", "FINANCIAL", "Y", "N", "N", "N"),
        ("REG001", "Missing Transcript", "ACADEMIC", "Y", "Y", "N", "N"),
        ("REG002", "Incomplete Application", "ACADEMIC", "Y", "Y", "N", "N"),
        ("LIB001", "Library Fine", "LIBRARY", "N", "N", "N", "Y"),
        ("PAR001", "Parking Violation", "PARKING", "N", "N", "N", "Y"),
        ("ACA001", "Academic Hold", "ACADEMIC", "Y", "Y", "Y", "N"),
    ]
    hc_rows = [(hc, hd, ht, pr, pg, pd, ar, None, "Y")
               for hc, hd, ht, pr, pg, pd, ar in hold_codes]
    _batch_insert(conn, """INSERT INTO burs_hold_code
        (hold_code, hold_desc, hold_type, prevent_reg, prevent_grades,
         prevent_diploma, auto_release, dept_owner, active)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9)""", hc_rows)

    acct_rows = []
    charge_rows = []
    pmt_rows = []
    hold_rows = []
    appeal_rows = []

    bsa_id_ctr = 1
    for stu_id in stu_ids:
        bal = round(random.uniform(0, 15000), 2)
        past_due = round(bal * random.uniform(0, 0.5), 2) if random.random() < 0.2 else 0.0
        status = "D" if past_due > 0 else random.choices(["C","S","C"], [0.90, 0.02, 0.08])[0]
        acct_rows.append((
            bsa_id_ctr, stu_id, date(2020, 8, 1), status,
            bal, past_due, 25000.0, "N",
        ))

        # Tuition charges
        for term_cd in TERM_CODES[-3:]:
            charge_rows.append((
                len(charge_rows) + 1, bsa_id_ctr, None,
                "TUITION", f"Tuition {term_cd}",
                round(random.uniform(3000, 9000), 2),
                _rand_date(date(2022,1,1), date(2025,1,15)),
                _rand_date(date(2022,2,1), date(2025,2,15)),
                term_cd, "N", None,
            ))

        # Payments
        if random.random() < 0.7:
            pmt_rows.append((
                len(pmt_rows) + 1, bsa_id_ctr,
                _rand_date(date(2024, 9, 1), date(2025, 3, 1)),
                random.choice(["CHECK","CREDIT","ACH","SCHOLARSHIP"]),
                round(random.uniform(500, 8000), 2),
                fake.uuid4()[:20],
                "STUDENT_PORTAL", "Y",
            ))

        # Some students have holds
        if past_due > 500 and random.random() < 0.4:
            placed_dt = _rand_date(date(2024, 8, 1), date(2025, 1, 1))
            hold_rows.append((
                len(hold_rows) + 1, bsa_id_ctr,
                random.choice(["FIN001","FIN002","ACA001"]),
                placed_dt, None, None, None, round(past_due, 2), None,
            ))

        # Tuition appeals for a subset
        if random.random() < 0.04:
            appeal_rows.append((
                len(appeal_rows) + 1, bsa_id_ctr, CURRENT_TERM,
                random.choices(APPEAL_CODES, APPEAL_CODE_WEIGHTS)[0],
                _rand_date(date(2024, 10, 1), date(2025, 3, 1)),
                round(random.uniform(200, 5000), 2),
                random.choice(["P","A","D"]),
                None, None, None, None,
            ))

        bsa_id_ctr += 1

    _batch_insert(conn, """INSERT INTO burs_student_account
        (bsa_id, student_nbr, acct_open_dt, acct_status,
         current_balance, past_due_amt, credit_limit, payment_plan_fg)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8)""", acct_rows)

    _batch_insert(conn, """INSERT INTO burs_charge_line
        (bcl_id, bsa_id, billing_period_id, charge_type, charge_desc,
         charge_amount, charge_date, due_date, term_cd, waived_fg, waive_reason)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11)""", charge_rows)

    _batch_insert(conn, """INSERT INTO burs_payment
        (bpmt_id, bsa_id, pmt_date, pmt_method, pmt_amount,
         pmt_reference, pmt_source, applied_fg)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8)""", pmt_rows)

    if hold_rows:
        _batch_insert(conn, """INSERT INTO burs_student_hold
            (bsh_id, bsa_id, hold_code, placed_dt, placed_by,
             released_dt, released_by, hold_amt, hold_notes)
            VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9)""", hold_rows)

    if appeal_rows:
        _batch_insert(conn, """INSERT INTO tutn_appeal_wrk
            (taw_id, taw_acct_ref, taw_term_cd, taw_appeal_cd, taw_appeal_dt,
             taw_credit_amt, taw_stat_flg, taw_reviewer, taw_review_dt,
             taw_doc_url, taw_notes)
            VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11)""", appeal_rows)

    console.print(f"  Inserted {bsa_id_ctr-1} bursar accounts, {len(charge_rows)} charges, {len(hold_rows)} holds, {len(appeal_rows)} appeals")


def _seed_academic_exceptions(conn, enrl_ids: list[int]) -> None:
    """~2k academic exception work table rows — the primary demo WRK table."""
    if not _table_empty(conn, "acad_exception_wrk"):
        return

    # Sample from enrollments
    sample_enrl = random.sample(enrl_ids, min(2000, len(enrl_ids)))
    rows = []
    for aew_id, er_id in enumerate(sample_enrl, start=1):
        exc_type = random.choices(EXCEPTION_TYPES, EXCEPTION_TYPE_WEIGHTS)[0]
        stat = random.choices(EXCEPTION_STATUSES, EXCEPTION_STATUS_WEIGHTS)[0]
        impact = round(random.uniform(-0.8, 1.2), 3) if exc_type == "GRD_CHNG" else 0.0
        subm_dt = _rand_date(date(2021, 1, 1), date(2025, 3, 1))
        dcsn_dt = subm_dt + timedelta(days=random.randint(5, 45)) if stat != "PEND" else None
        rows.append((
            aew_id, er_id, stat, exc_type, impact,
            None,     # aew_revr_id — polymorphic, intentionally left null in seed
            random.choice(["Y","N"]),   # dept_aprv
            random.choice(["Y","N","N"]),  # dean_aprv
            subm_dt, dcsn_dt, None,
        ))

    sql = """INSERT INTO acad_exception_wrk
             (aew_id, aew_enrl_key, aew_stat_cd, aew_type_cd, aew_impact_gpa,
              aew_revr_id, aew_dept_aprv, aew_dean_aprv,
              aew_subm_dt, aew_dcsn_dt, aew_notes)
             VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11)"""
    _batch_insert(conn, sql, rows, batch_size=500)
    console.print(f"  Inserted {len(rows)} academic exceptions (ACAD_EXCEPTION_WRK)")


def _seed_research(conn, instr_ids: list[int], dept_ids: list[int]) -> None:
    """Research projects, grants, IRB, faculty appointments, grant allocations."""
    if not _table_empty(conn, "faculty_appt"):
        return

    # Faculty appointments — one per instructor (FA_APPT_ID = INSTR_ID, same value)
    fa_rows = []
    for instr_id in instr_ids:
        fa_rows.append((
            instr_id,  # fa_appt_id = instr_id (same value, the key mapping)
            random.choice(dept_ids),
            random.choice(INSTR_RANKS),
            random.choice(["Y","N","N"]),
            round(random.uniform(0.5, 1.0), 3),
            "TENURE_TRACK",
            date(2010, 8, 1), None, "A",
            round(random.uniform(0.1, 0.6), 2),
            round(random.uniform(0.2, 0.6), 2),
            round(random.uniform(0.1, 0.3), 2),
        ))

    _batch_insert(conn, """INSERT INTO faculty_appt
        (fa_appt_id, fa_dept_id, fa_rank, fa_tenure_trk, fa_fte, fa_appt_type,
         fa_start_dt, fa_end_dt, fa_status, fa_research_pct, fa_teach_pct, fa_service_pct)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12)""", fa_rows)

    # Research projects and grants
    proj_rows = []
    grant_rows = []
    irb_rows = []
    gaw_rows = []

    for proj_id in range(1, 51):  # 50 projects
        pi_id = random.choice(instr_ids)
        dept_id = random.choice(dept_ids)
        start = _rand_date(date(2018, 1, 1), date(2023, 6, 1))
        end = start + timedelta(days=random.randint(365, 1825))
        status = random.choices(["A","C","H"], [0.6, 0.3, 0.1])[0]
        proj_rows.append((
            proj_id, fake.catch_phrase()[:200],
            random.choice(["BASIC","APPLIED","CLINICAL","TRANSLATIONAL"]),
            pi_id, dept_id, start, end, status,
            round(random.uniform(50000, 2000000), 2),
            round(random.uniform(0.25, 0.55), 4),
            random.choice(["FEDERAL","PRIVATE","STATE","INDUSTRY"]),
        ))

        # Grant for this project
        agency = random.choice(GRANT_AGENCIES)
        grant_amt = round(random.uniform(50000, 1500000), 2)
        grant_rows.append((
            proj_id, proj_id,
            f"{agency[0]}-{proj_id:05d}",
            agency[1], agency[2],
            f"Grant: {fake.catch_phrase()[:200]}",
            grant_amt, round(grant_amt * 0.35, 2),
            start, start, end, "ACTIVE" if status == "A" else "CLOSED",
            f"99.{random.randint(100,999)}" if agency[2] == "FEDERAL" else None,
        ))

        # IRB protocol if clinical/applied
        if random.random() < 0.7:
            irb_status = random.choices(["APPROVED","PENDING","EXPIRED","CLOSED"], [0.5,0.2,0.2,0.1])[0]
            irb_rows.append((
                proj_id, proj_id, f"IRB-{proj_id:05d}",
                random.choice(["EXPEDITED","FULL_BOARD","EXEMPT"]),
                random.choice(["MINIMAL","MODERATE","GREATER"]),
                random.choice(["EXPEDITED","FULL_BOARD"]),
                start, start + timedelta(days=90),
                start + timedelta(days=455),
                None, irb_status, pi_id,
            ))

        # Grant allocations (GRANT_ALLOC_WRK — the opaque WRK table)
        n_alloc = random.randint(1, 3)
        for _ in range(n_alloc):
            alloc_pct = round(random.uniform(5, 50), 2)
            committed = round(grant_amt * alloc_pct / 100, 2)
            gaw_rows.append((
                len(gaw_rows) + 1,
                proj_id,  # gaw_grant_ref = GRANT_TBL.GRANT_ID
                random.choice(instr_ids),  # gaw_facappt_key = FACULTY_APPT.FA_APPT_ID
                f"FY{random.randint(2020,2025)}",
                alloc_pct, committed, round(committed * random.uniform(0.7, 1.0), 2),
                random.choices(["A","P","C"], [0.6,0.2,0.2])[0],
                start, end, None,
            ))

    # -------------------------------------------------------------------------
    # Overcommitted faculty cohort — 12 faculty each holding two active grants
    # with APPROVED IRBs, total effort summing to ~120%.  These are the rows
    # that the "exceeds 100 percent effort" query must find.
    # Projects 51-74 (2 per faculty). expiration_dt=None → no date-filter risk.
    # -------------------------------------------------------------------------
    overcommitted_faculty = instr_ids[:12]          # first 12 instructors
    oc_proj_start = date(2022, 9, 1)
    oc_proj_end   = date(2027, 8, 31)
    oc_proj_id    = 51

    for fa_id in overcommitted_faculty:
        dept_id = random.choice(dept_ids)
        for slot in range(2):          # two grants per faculty member
            pid = oc_proj_id
            oc_proj_id += 1
            grant_amt = round(random.uniform(200000, 800000), 2)

            proj_rows.append((
                pid, f"Overcommitted Research Project {pid}",
                "APPLIED", fa_id, dept_id,
                oc_proj_start, oc_proj_end, "A",
                grant_amt, round(random.uniform(0.40, 0.55), 4),
                random.choice(["FEDERAL", "PRIVATE"]),
            ))
            grant_rows.append((
                pid, pid,
                f"NIH-OC-{pid:05d}",
                "NIH", "FEDERAL",
                f"Overcommitted Grant {pid}",
                grant_amt, round(grant_amt * 0.40, 2),
                oc_proj_start, oc_proj_start, oc_proj_end,
                "ACTIVE", f"99.{800 + pid}",
            ))
            # IRB with no expiration — always passes any date filter
            irb_rows.append((
                pid, pid, f"IRB-OC-{pid:05d}",
                "FULL_BOARD", "GREATER", "FULL_BOARD",
                oc_proj_start,
                oc_proj_start + timedelta(days=90),
                None,       # expiration_dt = NULL → never expires
                None, "APPROVED", fa_id,
            ))
            # Single allocation at 60-65% per grant → 120-130% total per faculty
            alloc_pct  = round(random.uniform(60, 65), 2)
            committed  = round(grant_amt * alloc_pct / 100, 2)
            gaw_rows.append((
                len(gaw_rows) + 1,
                pid,    # gaw_grant_ref
                fa_id,  # gaw_facappt_key — same faculty member both slots
                "FY2025",
                alloc_pct, committed, round(committed * 0.85, 2),
                "A",    # gaw_status = Active
                oc_proj_start, oc_proj_end, "Overcommitted — flagged for review",
            ))

    _batch_insert(conn, """INSERT INTO research_project
        (project_id, project_title, project_type, pi_appt_id, dept_id,
         start_date, end_date, status, total_budget, indirect_rate, sponsor_type)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11)""", proj_rows)

    _batch_insert(conn, """INSERT INTO grant_tbl
        (grant_id, project_id, grant_nbr, agency_name, agency_type, grant_title,
         grant_amount, indirect_amt, award_date, start_date, end_date, grant_status, cfda_nbr)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13)""", grant_rows)

    if irb_rows:
        _batch_insert(conn, """INSERT INTO irb_protocol
            (irb_id, project_id, protocol_nbr, protocol_type, risk_level, review_type,
             submission_dt, approval_dt, expiration_dt, renewal_dt, irb_status, pi_appt_id)
            VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12)""", irb_rows)

    _batch_insert(conn, """INSERT INTO grant_alloc_wrk
        (gaw_id, gaw_grant_ref, gaw_facappt_key, gaw_bgt_period, gaw_alloc_pct,
         gaw_committed_amt, gaw_actual_amt, gaw_status, gaw_eff_dt, gaw_exp_dt, gaw_notes)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11)""", gaw_rows)

    console.print(f"  Inserted {len(proj_rows)} projects, {len(grant_rows)} grants, {len(irb_rows)} IRB, {len(gaw_rows)} allocations")


def _seed_housing(conn, stu_ids: list[int]) -> None:
    """Residential rooms, assignments, waitlist."""
    if not _table_empty(conn, "hsg_room_inventory"):
        return

    room_rows = []
    for i in range(1, N_HSG_ROOMS + 1):
        bldg = random.choice(["AUBURN","BIRCH","CEDAR","DOGWOOD","ELM","FIR"])
        rtype = random.choices(["SINGLE","DOUBLE","TRIPLE","SUITE"], [0.1,0.5,0.2,0.2])[0]
        cap = {"SINGLE":1,"DOUBLE":2,"TRIPLE":3,"SUITE":4}[rtype]
        room_rows.append((
            i, bldg, f"{random.randint(1,4):01d}{i:02d}", rtype, cap,
            random.choice(["M","F","C"]),
            random.randint(1,4),
            "AC,WIFI,DESK",
            round(random.uniform(2500, 5000), 2),
            "AVAILABLE",
        ))

    _batch_insert(conn, """INSERT INTO hsg_room_inventory
        (hsg_room_id, bldg_cd, room_nbr, room_type, capacity, gender_assn,
         floor_nbr, amenities, rate_per_sem, room_status)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10)""", room_rows)

    # Assignments — ~3k students in dorms
    dorm_students = random.sample(stu_ids, min(3000, len(stu_ids)))
    asgn_rows = []
    for i, stu_id in enumerate(dorm_students):
        room_id = random.randint(1, N_HSG_ROOMS)
        term_cd = random.choice(TERM_CODES[-4:])
        asgn_rows.append((
            i + 1, room_id, stu_id, term_cd,
            _rand_date(date(2021,6,1), date(2025,1,1)),
            None, None, "REGULAR", None,
        ))

    _batch_insert(conn, """INSERT INTO hsg_room_assignment
        (hra_id, hsg_room_id, student_id, term_cd, assignment_dt,
         check_in_dt, check_out_dt, assignment_type, roommate_pref)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9)""", asgn_rows)

    # Housing waitlist (HSG_WAITLIST_WRK)
    waitlist_sample = random.sample(stu_ids, 200)
    hww_rows = []
    for i, stu_id in enumerate(waitlist_sample, start=1):
        stat = random.choices(["A","O","X","C"], [0.6,0.1,0.2,0.1])[0]
        hww_rows.append((
            i, stu_id, CURRENT_TERM,
            random.choice(["STANDARD","ACCESSIBILITY","SINGLE"]),
            random.choice(["AUBURN","BIRCH","CEDAR"]),
            None, random.randint(1,200), stat,
            _rand_date(date(2024,10,1), date(2025,1,1)),
            date(2025,5,31), None,
        ))

    _batch_insert(conn, """INSERT INTO hsg_waitlist_wrk
        (hww_id, hww_stu_ref, hww_term_cd, hww_req_type, hww_pref_bldg,
         hww_pref_room, hww_priority, hww_stat_cd, hww_req_dt, hww_exp_dt, hww_notes)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11)""", hww_rows)

    console.print(f"  Inserted {N_HSG_ROOMS} dorm rooms, {len(asgn_rows)} assignments, {len(hww_rows)} waitlist rows")


def _seed_hr(conn, instr_ids: list[int]) -> None:
    """STAFF_HR_XREF crosswalk between INSTR_TBL and HR/Workday IDs."""
    if not _table_empty(conn, "staff_hr_xref"):
        return

    pos_rows = [
        ("PROF001", "Professor", "FACULTY", None, "P6", 1.0, "Y"),
        ("PROF002", "Associate Professor", "FACULTY", None, "P5", 1.0, "Y"),
        ("PROF003", "Assistant Professor", "FACULTY", None, "P4", 1.0, "Y"),
        ("LEC001",  "Lecturer", "FACULTY", None, "P3", 1.0, "Y"),
        ("ADMIN001","Department Administrator", "STAFF", None, "S5", 1.0, "Y"),
    ]
    _batch_insert(conn, """INSERT INTO hr_position
        (position_cd, position_title, position_type, dept_id, pay_grade, fte_budget, active)
        VALUES (:1,:2,:3,:4,:5,:6,:7)""", pos_rows)

    xref_rows = []
    hr_appt_rows = []
    pos_codes = [r[0] for r in pos_rows[:4]]

    for shx_id, instr_id in enumerate(instr_ids, start=1):
        hr_emp_id = f"WD{instr_id:07d}"
        xref_rows.append((
            shx_id, instr_id, hr_emp_id,
            date(2015, 1, 1), None, "PRIMARY", None, None,
        ))
        hr_appt_rows.append((
            shx_id, hr_emp_id,
            random.choice(pos_codes),
            "REGULAR", 1.0,
            date(2015, 1, 1), None, "A", "P4",
        ))

    _batch_insert(conn, """INSERT INTO staff_hr_xref
        (shx_id, shx_instr_id, shx_hr_emp_id, shx_eff_dt, shx_exp_dt,
         shx_xref_typ, shx_dept_id, shx_cre_dt)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8)""", xref_rows)

    _batch_insert(conn, """INSERT INTO hr_appointment
        (hr_appt_id, shx_hr_emp_id, position_cd, appt_type, fte,
         appt_start, appt_end, appt_status, salary_grade)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9)""", hr_appt_rows)

    console.print(f"  Inserted {len(xref_rows)} HR crosswalk rows (STAFF_HR_XREF)")


# ---------------------------------------------------------------------------
# Academic Standing (SAP) — one row per student per term
# ---------------------------------------------------------------------------

# Term date lookup for eff_dt/exp_dt alignment
_TERM_DATES: dict[str, tuple[date, date]] = {}
for _tc in TERM_CODES:
    _yr  = int(_tc[:4])
    _sem = _tc[4:]
    if _sem == "01":
        _TERM_DATES[_tc] = (date(_yr, 1, 15), date(_yr, 5, 15))
    else:
        _TERM_DATES[_tc] = (date(_yr, 8, 25), date(_yr, 12, 20))


def _seed_acad_stat_tbl(conn, stu_ids: list[int]) -> None:
    """SAP standing: one record per student per term (sampled ~60% of students per term).

    Status distribution: ~70% G=Good Standing, ~20% P=Probation, ~8% W=Warning, ~4% S=Suspension.
    GPA requirement is always 2.0; actual GPA is drawn from a distribution that explains the status
    (students on probation/suspension realistically have lower GPAs).
    """
    if not _table_empty(conn, "acad_stat_tbl"):
        console.print("  ACAD_STAT_TBL already populated — skipping")
        return

    rows = []
    as_id = 1

    # Sample ~60% of students per term to avoid a row per every student every term
    rng = random.Random(42)

    for term_cd in TERM_CODES:
        term_start, term_end = _TERM_DATES[term_cd]
        sample_size = int(len(stu_ids) * 0.60)
        term_students = rng.sample(stu_ids, sample_size)

        for stu_id in term_students:
            stat_cd = rng.choices(["G", "P", "W", "S"], [0.70, 0.20, 0.08, 0.04])[0]

            gpa_req = 2.000
            if stat_cd == "G":
                gpa_act = round(rng.uniform(2.00, 4.00), 3)
            elif stat_cd == "P":
                gpa_act = round(rng.uniform(1.50, 2.20), 3)
            elif stat_cd == "W":
                gpa_act = round(rng.uniform(1.80, 2.30), 3)
            else:  # S=Suspension
                gpa_act = round(rng.uniform(1.00, 1.80), 3)

            hrs_req = 12.0
            hrs_act = round(rng.uniform(6.0, 18.0), 1)

            appeal_fg = "Y" if stat_cd in ("P", "S") and rng.random() < 0.20 else "N"
            if appeal_fg == "Y":
                delta = (term_end - term_start).days
                appeal_dt = term_start + timedelta(days=rng.randint(0, max(delta, 0)))
            else:
                appeal_dt = None

            rows.append((
                as_id,
                stu_id,
                term_cd,
                stat_cd,
                gpa_req,
                gpa_act,
                hrs_req,
                hrs_act,
                appeal_fg,
                appeal_dt,
                None,         # as_note
                term_start,   # as_eff_dt — start of the term
                term_end,     # as_exp_dt — end of the term
                term_end,     # upd_dt
            ))
            as_id += 1

    _batch_insert(conn, """INSERT INTO acad_stat_tbl
        (as_id, as_stu_id, as_term_cd, as_stat_cd, as_gpa_req, as_gpa_act,
         as_hrs_req, as_hrs_act, as_appeal_fg, as_appeal_dt, as_note,
         as_eff_dt, as_exp_dt, upd_dt)
        VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14)""", rows)

    n_prob = sum(1 for r in rows if r[3] == "P")
    console.print(f"  Inserted {len(rows):,} academic standing rows "
                  f"({n_prob:,} on Probation) across {len(TERM_CODES)} terms")


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def run_seed() -> None:
    console.rule("[bold cyan]Westfield University Seeder")
    with get_connection() as conn:
        console.print("Seeding DEPT_TBL...")
        dept_ids = _seed_departments(conn)

        console.print("Seeding INSTR_TBL...")
        instr_ids = _seed_instructors(conn, dept_ids)

        console.print("Seeding ROOM_INVT (classrooms)...")
        room_ids = _seed_rooms(conn)

        console.print("Seeding TERM_TBL...")
        _seed_terms(conn)

        console.print("Seeding STU_MST...")
        stu_ids = _seed_students(conn, dept_ids)

        console.print("Seeding ACAD_STAT_TBL (SAP standing)...")
        _seed_acad_stat_tbl(conn, stu_ids)

        console.print("Seeding CRS_CAT...")
        crs_nbrs = _seed_courses(conn, dept_ids)

        console.print("Seeding CRS_SECT...")
        sect_ids = _seed_sections(conn, crs_nbrs, instr_ids, room_ids, dept_ids)

        console.print("Seeding ENRL_REC...")
        enrl_ids = _seed_enrollments(conn, stu_ids, sect_ids)

        console.print("Seeding GRD_HIST...")
        _seed_grade_history(conn, enrl_ids)

        console.print("Seeding FinancialAid tables...")
        _seed_financial_aid(conn, stu_ids)

        console.print("Seeding Bursar tables...")
        _seed_bursar(conn, stu_ids)

        console.print("Seeding ACAD_EXCEPTION_WRK...")
        _seed_academic_exceptions(conn, enrl_ids)

        console.print("Seeding Research tables...")
        _seed_research(conn, instr_ids, dept_ids)

        console.print("Seeding Housing tables...")
        _seed_housing(conn, stu_ids)

        console.print("Seeding HR tables...")
        _seed_hr(conn, instr_ids)

    console.rule("[bold green]Westfield University seed complete")


if __name__ == "__main__":
    import src.schemas.university.plugin  # noqa: F401
    run_seed()
