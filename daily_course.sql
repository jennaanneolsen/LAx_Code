
--run this file daily

drop table BK_DAILY_PREP;
create table BK_DAILY_PREP as 
select distinct 
  sysdate as date_run,
  trunc((extract(day from sysdate)/7),0)+1 as week_of_month,
  l.*, case 
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
    g.course_number as course_code,
    g.course_version,
    g.cv_launch,
    g.college_code,
    g.level_code,
    g.term_start_date,
    g.term_end_date,
    g.month_of_term,
    case when e.task_atmpts>0 then 1 else 0 end as task_atmpt,
    case when j.N_units>0 then 1 else 0 end as unit_atmpt,
    case when k.N_preasmts>0 then 1 else 0 end as preasmt_atmpt,
    max(h.assessment_pass + h.assessment_fail) over (partition by h.student_pidm, h.term_code, h.course_number) as oa_atmpt,
    max(h.course_completion) over (partition by h.student_pidm, h.term_code, h.course_number) as completed
  from BK_WEEKLY_ACTIVE_ASMT g
  left join wgubi.vw_rst_assessment h
    on g.student_pidm=h.student_pidm
    and g.term_code=h.term_code
    and g.course_number=h.course_number
    and h.assessment_category='Assessment'
  left join (select distinct
          a.student_pidm, a.course_number,
          sum(b.N_complete) over (partition by b.student_pidm, b.course_number) as N_units 
        from BK_WEEKLY_ACTIVE_ASMT a
        left join wgubi.fact_student_engagement b
          on a.student_pidm=b.student_pidm
          and a.course_number=b.course_number
          and b.calendar_date between a.term_start_date and a.term_end_date) j
    on g.student_pidm=j.student_pidm
    and g.course_number=j.course_number
  left join (select distinct
          a.student_pidm, a.course_number, 
          count(b.assess_attempt_id) over (partition by b.student_pidm, b.assessment_code) as N_preasmts
        from BK_WEEKLY_ACTIVE_ASMT a
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
        from BK_WEEKLY_ACTIVE_ASMT c
        left join wgubi.vw_rst_performance_assessment d
          on d.student_pidm=c.student_pidm
          and d.assessment_code=c.assessment_code
          and d.task_submit_date between c.term_start_date and c.term_end_date
        where c.assessment_type='Performance'
          and d.task_returned_counter = 1) e
    on g.student_pidm=e.student_pidm
    and g.course_number=e.course_number) l;
select * from BK_DAILY_PREP;

drop table BK_DAILY_COURSE;
create table BK_DAILY_COURSE as 
select  
  e.*,
  d.program_version,
  d.course_version,
  d.cv_launch,
  coalesce(d.cnt,0) as N,
  f.course_title,
  case when f.college_code='LA' then 'GE' else f.college_code end as PDEV_team, 
  f.dept_code,
  f.subject_code,
  h.area_of_study
from (select a.*, b.program_code, b.course_code, c.month_of_term
  from (select distinct date_run, week_of_month, status from BK_DAILY_PREP) a
  left join (select distinct date_run, program_code, course_code from BK_DAILY_PREP) b
    on a.date_run=b.date_run
  left join (select distinct date_run, month_of_term from BK_DAILY_PREP) c
    on a.date_run=c.date_run) e 
left join (select distinct 
      course_code,
      course_version,
      cv_launch,
      month_of_term,
      program_code,
      program_version,
      status, 
      count(distinct(student_pidm)) as cnt
    from BK_DAILY_PREP 
    group by course_code, course_version, cv_launch, month_of_term, program_code, program_version, status) d
  on e.status=d.status
  and e.course_code=d.course_code
  and e.month_of_term=d.month_of_term
  and e.program_code=d.program_code
left join wgubi.vw_rst_program_guide  h
  on e.program_code=h.program_code
  and d.program_version=h.program_version
  and e.course_code=h.course_number
join wgubi.dim_assessment f
  on e.course_code=f.course_number;
select * from BK_DAILY_COURSE where rownum<20;
