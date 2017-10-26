    
drop table m7_course_prep1; /* m7 = students whose terms ended last month (they are in "month 7" of term) */
create table m7_course_prep1 as 
select distinct
  a.student_pidm,
  a.program_code,
  m.program_version,
  n.term_code,
  n.term_sequence,
  a.course_number,
  a.course_version,
  f.assessment_code,
  f.assessment_type,
  f.assessment_sub_type,
  n.college_code,
  n.level_code,
  a.term_start_date,
  a.term_end_date
from wgubi.vw_rst_assessment a
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
  and trunc(a.term_end_date) between '01-OCT-17' and sysdate
  and n.term_otp is not null;
select distinct term_code, count(*) over (partition by term_code) as N from m7_course_prep1 order by term_code;

drop table m7_course_prep2;
create table m7_course_prep2 as 
select distinct l.*, case 
    when l.completed=1 then 'completed' 
    when (l.oa_atmpt=1 or l.task_atmpt=1) then 'attempted'
    when (l.unit_atmpt=1 or l.preasmt_atmpt=1) then 'engaged'
    else 'dormant' end as status  
  from (select distinct 
      g.student_pidm,
      g.program_code,
      g.program_version,
      g.term_code,
      g.term_sequence,
      g.course_number,
      g.course_version,
      g.college_code,
      g.level_code,
      g.term_start_date,
      g.term_end_date,
      case when e.task_atmpts>0 then 1 else 0 end as task_atmpt,
      case when j.N_units>0 then 1 else 0 end as unit_atmpt,
      case when k.N_preasmts>0 then 1 else 0 end as preasmt_atmpt,
      max(h.assessment_pass + h.assessment_fail) over (partition by h.student_pidm, h.term_code, h.course_number) as oa_atmpt,
      max(h.course_completion) over (partition by h.student_pidm, h.term_code, h.course_number) as completed
    from m7_course_prep1 g
    left join wgubi.vw_rst_assessment h
      on g.student_pidm=h.student_pidm
      and g.term_code=h.term_code
      and g.course_number=h.course_number
    left join (select distinct
            a.student_pidm, a.course_number,
            sum(b.N_complete) over (partition by b.student_pidm, b.course_number) as N_units 
          from m7_course_prep1 a
          left join wgubi.fact_student_engagement b
            on a.student_pidm=b.student_pidm
            and a.course_number=b.course_number
            and b.calendar_date between a.term_start_date and a.term_end_date) j
      on g.student_pidm=j.student_pidm
      and g.course_number=j.course_number
    left join (select distinct
            a.student_pidm, a.course_number, 
            count(b.assess_attempt_id) over (partition by b.student_pidm, b.assessment_code) as N_preasmts
          from m7_course_prep1 a
          left join wgubi.vw_fact_oa_assessment_attempt b
            on a.student_pidm=b.student_pidm
            and a.assessment_code=b.assessment_code
            and a.term_start_date<=b.assess_date
          where substr(a.assessment_sub_type,1,3)='Pre') k
      on g.student_pidm=k.student_pidm
      and g.course_number=k.course_number
    left join (select distinct 
            c.student_pidm, c.course_number, 
            count(d.actionlogid) over (partition by d.student_pidm, d.assessment_code) as task_atmpts
          from m7_course_prep1 c
          left join wgubi.vw_rst_performance_assessment d
            on d.student_pidm=c.student_pidm
            and d.assessment_code=c.assessment_code
            and d.task_submit_date between c.term_start_date and c.term_end_date
          where c.assessment_type='Performance'
            and d.task_returned_counter = 1) e
      on g.student_pidm=e.student_pidm
      and g.course_number=e.course_number) l;
select distinct status, count(*) over (partition by status) as N from m7_course_prep2;
select * from m7_course_prep2;

insert into BK_CRS_PROG_MONTH
select distinct 
  e.*,
  case when f.college_code='LA' then 'GE' else f.college_code end as PDEV_team,
  f.dept_code,
  f.subject_code,
  f.course_title,
  f.course_level,
  h.competency_units,
  h.area_of_study,
  h.path_order,
  h.suggested_term
from (select distinct
    trunc(term_end_date) as month_end_date,
    term_code,
    college_code,
    level_code,
    program_code,
    program_version,
    course_number,
    course_version,
    count(distinct(student_pidm)) over (partition by term_code, program_code, program_version, course_number, course_version) as m7_N,
    sum(case when status='completed' then 1 else 0 end) over (partition by term_code, program_code, program_version, course_number, course_version) as m7_N_completers,
    sum(case when status='attempted' then 1 else 0 end) over (partition by term_code, program_code, program_version, course_number, course_version) as m7_N_attempters,
    sum(case when status='engaged' then 1 else 0 end) over (partition by term_code, program_code, program_version, course_number, course_version) as m7_N_engagers,
    sum(case when status='dormant' then 1 else 0 end) over (partition by term_code, program_code, program_version, course_number, course_version) as m7_N_nonstarters      
  from m7_course_prep2) e
join wgubi.vw_rst_program_guide  h
  on e.program_code=h.program_code
  and e.program_version=h.program_version
  and e.course_number=h.course_number
join wgubi.dim_assessment f
  on e.course_number=f.course_number;
select distinct term_code, count(*) over (partition by term_code) as N from BK_CRS_PROG_MONTH order by term_code;
