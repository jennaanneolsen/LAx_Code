
--run this file weekly

insert into BK_WEEKLY_COURSE
select 
  e.date_run,
  e.status,
  e.course_code,
  e.program_code,
  e.month_of_term,
  e.week_of_month,
  e.course_version,
  e.program_version,
  e.N,
  e.course_title,
  e.pdev_team,
  e.dept_code,
  e.subject_code,
  h.course_level,
  h.competency_units,
  e.area_of_study,
  h.path_order,
  h.suggested_term,
  e.cv_launch
from BK_DAILY_COURSE e
join wgubi.vw_rst_program_guide  h
  on e.program_code=h.program_code
  and e.program_version=h.program_version
  and e.course_code=h.course_number;
select distinct date_run, week_of_month, month_of_term, 
  count(*) over (partition by date_run, week_of_month, month_of_term) as N 
  from bk_weekly_course order by date_run, week_of_month;
  
drop table BK_WEEKLY_ACTIVE_ASMT;
create table BK_WEEKLY_ACTIVE_ASMT as 
select distinct
  a.student_pidm,
  a.program_code,
  m.program_version,
  n.term_code,
  n.term_sequence,
  a.course_number,
  a.course_version,
  trunc(b.launch_date) as cv_launch,
  f.assessment_code,
  f.assessment_type,
  f.assessment_sub_type,
  n.college_code,
  n.level_code,
  a.term_start_date,
  a.term_end_date,
  1+ extract(month from sysdate)-extract(month from a.term_start_date) as month_of_term
from wgubi.vw_rst_assessment a
join wgubi.vw_dim_course_version_pams b
  on a.course_number=b.code
  and a.course_version=b.major_version
join wgubi.vw_course_version_assessments f
  on a.course_number=f.course_number
  and a.course_version=f.course_version
join wgubi.vw_rst_student n
  on a.student_pidm=n.student_pidm
  and a.program_code=n.program_code
  and a.term_code=n.term_code
join wgubi.vw_rst_program_guide m
  on a.program_code=m.program_code
  and n.term_code_ctlg=m.term_code_ctlg
where a.course_assign=1
  and trunc(a.term_end_date)>sysdate
  and n.active=1;
select distinct month_of_term, count(*) over (partition by month_of_term) as N from (select distinct student_pidm, month_of_term from BK_WEEKLY_ACTIVE_ASMT);


--Search for column
select * from ALL_TAB_COLUMNS where owner='WGUBI' and COLUMN_NAME like 'LAUNCH_DATE%';
select * from wgubi.vw_dim_course_version_pams where rownum<20;
select * from wgubi.dim_course_version_pams where rownum<20;