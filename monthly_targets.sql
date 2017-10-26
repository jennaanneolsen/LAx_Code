
-- run this monthly

drop table BK_TARG_COLL_MONTH;
create table BK_TARG_COLL_MONTH as 
select 
  TRUNC(end_date) as prev_month_end, 
  metric_category as college_code,
  max(case when metric='T2T Retention' then target else NULL end) as Retention_Rate,
  max(case when metric='OTP' then target else NULL end) as OTP_Rate,
  max(case when metric='Completion Rate' then target else NULL end) as Completion_Rate,
  max(case when metric='Drop Rate' then target else NULL end) as Drop_Rate,
  max(case when metric='Enroll' then target else NULL end) as Enroll,
  max(case when metric='Matric' then target else NULL end) as Matric,
  max(case when metric='Graduates' then target else NULL end) as Graduates,
  max(case when metric='OA Avg Balance' then target else NULL end) as OA_Avg_Balance,
  max(case when metric='OA Avg Discrimination' then target else NULL end) as OA_Avg_Discrimination,
  max(case when metric='OA Avg Reliability' then target else NULL end) as OA_Avg_Reliability,
  max(case when metric='OA Pass Rate' then target else NULL end) as OA_PCT_PR_IN_THRESH,
  max(case when metric='PA Avg Balance' then target else NULL end) as PA_Avg_Balance,
  max(case when metric='PA Avg Discrimination' then target else NULL end) as PA_Avg_Discrimination,
  max(case when metric='PA Avg Reliability' then target else NULL end) as PA_Avg_Reliability,
  max(case when metric='PA PCT PR IN THRESH' then target else NULL end) as PA_PCT_PR_IN_THRESH
from wgubi.de_exe_targets 
where time_period='Month'
  and metric_category in ('WGU','Overall','GE','BU','IT','HE','TC')
  and trunc(end_date,'month')<sysdate
  group by TRUNC(end_date), metric_category;
select * from BK_TARG_COLL_MONTH;

drop table BK_TARG_PROG_MONTH;
create table BK_TARG_PROG_MONTH as
select fiscal_year, program_code, t2t, term_otp, drop_rate FROM wgubi.vw_program_goals;
select * from BK_TARG_PROG_MONTH;
