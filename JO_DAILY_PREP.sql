--drop table LAX_DAILY_PREP;
create table LAX_DAILY_PREP as
--BK_DAILY_PREP creation
select distinct 
  sysdate as date_run,
  trunc((extract(day from sysdate)/7),0)+1 as week_of_month,
  l.*, case 
  when l.completed=1 then 'completed' 
  when (l.oa_atmpt=1 or l.task_atmpt=1) then 'attempted'
  when (l.unit_atmpt=1 or l.preasmt_atmpt=1) then 'engaged'
  else 'dormant' end as status  
from (
  select distinct 
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
  left join (
      select distinct(student_pidm), course_number, calendar_date, sum(N_complete) over (partition by student_pidm, course_number, calendar_date) as N_units  
       from wgubi.fact_student_engagement 
      )j 
    on g.student_pidm = j.student_pidm
    and g.course_number = j.course_number
    and j.calendar_date between g.term_start_date and g.term_end_date
  left join (
    select distinct(student_pidm), assessment_code, assess_date, count(assess_attempt_id) over (partition by student_pidm, assessment_code, assess_date) as N_preasmts 
      from wgubi.vw_fact_oa_assessment_attempt 
    ) k
    on g.student_pidm = k.student_pidm
    and g.assessment_code = k.assessment_code
    and k.assess_date between g.term_start_date and g.term_end_date
    and g.assessment_sub_type like 'Pre%'
  left join (
      select distinct 
          c.student_pidm, c.course_number, 
          count(d.actionlogid) over (partition by d.student_pidm, d.assessment_code) as task_atmpts
        from BK_WEEKLY_ACTIVE_ASMT c
        left join wgubi.vw_rst_performance_assessment d
          on d.student_pidm=c.student_pidm
          and d.assessment_code=c.assessment_code
          and d.task_submit_date between c.term_start_date and c.term_end_date
        where c.assessment_type='Performance'
          and d.task_returned_counter = 1
        )e
    on g.student_pidm = e.student_pidm
    and g.course_number = e.course_number
    and g.assessment_type = 'Performance'
)l