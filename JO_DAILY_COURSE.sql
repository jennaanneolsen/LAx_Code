--drop table LAX_DAILY_COURSE;
create table LAX_DAILY_COURSE as
select  
  e.*,
  coalesce(d.cnt,0) as N,
  f.course_title,
  case when f.college_code='LA' then 'GE' else f.college_code end as PDEV_team, 
  f.dept_code,
  f.subject_code,
  h.area_of_study
from 
  LAX_DAILY_PREP e 
left join (
  select course_code, course_version, cv_launch, month_of_term, program_code, program_version, status, 
      count(distinct(student_pidm)) as cnt
    from LAX_DAILY_PREP 
    --group by has the same effect as distinct in this query (and group by is required for the count)
    group by course_code, course_version, cv_launch, month_of_term, program_code, program_version, status 
  )d 
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
