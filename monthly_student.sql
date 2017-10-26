
-- run this monthly

drop table BK_ACTIVES;
create table BK_ACTIVES as 
  select distinct
   last_day(sysdate-27) as prev_month_end,
    b.college_code,
    b.level_code,
    b.program_code,
    e.program_version,
    b.term_code_ctlg,
    b.prog_cus_required,
    b.PROG_CUS_REMAINING,
    b.student_pidm,
    b.campus_description,
    b.student_resi_state,
    case when d.marital_status not in ('Married','Single') then 'Other' else d.marital_status end as marital_status,
    d.gender,
    d.age,
    b.term_sequence,
    case when (sysdate-b.term_start_date)<27 then 1
      when (sysdate-b.term_start_date) between 27 and 56 then 2
      when (sysdate-b.term_start_date) between 57 and 86 then 3
      when (sysdate-b.term_start_date) between 87 and 116 then 4
      when (sysdate-b.term_start_date) between 117 and 146 then 5
      when (sysdate-b.term_start_date) between 147 and 176 then 6 end as term_month
  from wgubi.vw_rst_student b
  join wgubi.vw_student_demographics d
    on b.student_pidm=d.student_pidm
  join wgubi.vw_pdm_prog e
    on b.program_code=e.program_code
    and b.term_code_ctlg=e.term_code_ctlg
  where b.term_end_date > sysdate
    and b.month_end_date > sysdate
    and active=1;
select distinct prev_month_end from BK_ACTIVES order by prev_month_end;


drop table prep_drops;
create table prep_drops as 
select distinct
  prev_month_end,
  college_code,
  level_code,
  program_code,
  program_version,
  sum(drop_return) as N_drop_returns,
  sum(drops) as N_drops,
  sum(drop_denom) as N_drop_denom
from (select distinct
    trunc(s.month_end_date) as prev_month_end,
    s.college_code,
    s.level_code,
    s.program_code,
    e.program_version,
    s.student_pidm,
    s.return_from_drop as drop_return,
    s.drops,
    s.STUDENT_MONTH_RETENTION_DEN as drop_denom
  from wgubi.vw_rst_student s
  join wgubi.vw_pdm_prog e
      on s.program_code=e.program_code
      and s.term_code_ctlg=e.term_code_ctlg
  where trunc(s.month_end_date) between '01-SEP-17' and sysdate
      and (s.return_from_drop=1 or s.STUDENT_MONTH_RETENTION_DEN=1))
group by 
  prev_month_end,
  college_code,
  level_code,
  program_code,
  program_version;
select distinct prev_month_end from prep_drops order by prev_month_end;


drop table prep_t2t;
create table prep_t2t as 
select distinct
  prev_month_end,
  college_code,
  level_code,
  program_code,
  program_version,
  sum(t2t_reten_numer) as N_t2t_retains,
  sum(t2t_reten_denom) as N_t2t_denom
from (select distinct
    trunc(b.month_end_date) as prev_month_end,
    b.college_code,
    b.level_code,
    b.program_code,
    e.program_version,
    b.student_pidm,
    b.t2t_reten_denom,
    b.t2t_reten_numer
  from wgubi.rst_student_term_2_term b
  join wgubi.vw_rst_student s
     on s.student_pidm=b.student_pidm
     and s.program_code=b.program_code
     and trunc(s.month_end_date)=trunc(b.month_end_date)
  join wgubi.vw_pdm_prog e
      on s.program_code=e.program_code
      and s.term_code_ctlg=e.term_code_ctlg 
  where trunc(s.month_end_date) between '01-SEP-17' and sysdate
      and b.t2t_reten_denom=1)
group by 
  prev_month_end,
  college_code,
  level_code,
  program_code,
  program_version;
select * from prep_t2t;


drop table prep_grads;
create table prep_grads as 
select distinct
  prev_month_end,
  college_code,
  level_code,
  program_code,
  program_version,
  sum(active) as N_actives,
  sum(newbie) as N_newbies,
  sum(grad) as N_grads
from (select distinct
    trunc(s.month_end_date) as prev_month_end,
    s.college_code,
    s.level_code,
    s.program_code,
    e.program_version,
    s.student_pidm,
    s.active,
    s.new_start as newbie,
    s.grad
  from wgubi.vw_rst_student s
  join wgubi.vw_pdm_prog e
      on s.program_code=e.program_code
      and s.term_code_ctlg=e.term_code_ctlg
  where trunc(s.month_end_date) between '01-SEP-17' and sysdate
      and (s.active=1 or s.new_start=1 or s.grad=1))
group by 
  prev_month_end,
  college_code,
  level_code,
  program_code,
  program_version;
select * from prep_grads;


drop table prep_otp;
create table prep_otp as
select distinct
  prev_month_end,
  college_code,
  level_code,
  program_code,
  program_version,
  count(*) as N_otp_denom,
  sum(term_otp) as N_otp
from (select distinct
    trunc(s.month_end_date) as prev_month_end,
    s.college_code,
    s.level_code,
    s.program_code,
    e.program_version,
    s.student_pidm,
    s.term_otp
  from wgubi.vw_rst_student s
  join wgubi.vw_pdm_prog e
    on s.program_code=e.program_code
    and s.term_code_ctlg=e.term_code_ctlg
  where trunc(s.month_end_date) between '01-SEP-17' and sysdate
    and term_otp is not null )
group by 
  prev_month_end,
  college_code,
  level_code,
  program_code,
  program_version;
select * from prep_otp;


insert into BK_STUD_PROG_MONTH 
select distinct
    a.*,
    coalesce(N_actives,0) as N_actives,
    coalesce(N_newbies,0) as N_newbies,
    coalesce(N_grads,0) as N_grads,
    coalesce(N_drop_returns,0) as N_drop_returns,
    coalesce(N_drops,0) as N_drops,
    coalesce(N_drop_denom,0) as N_drop_denom,
    coalesce(N_t2t_retains,0) as N_t2t_retains,
    coalesce(N_t2t_denom,0) as N_t2t_denom,
    coalesce(N_otp_denom,0) as N_otp_denom,
    coalesce(N_otp,0) as N_otp
from (select distinct prev_month_end, college_code, level_code, program_code, program_version from prep_drops
      union select distinct prev_month_end, college_code, level_code, program_code, program_version from prep_t2t
      union select distinct prev_month_end, college_code, level_code, program_code, program_version from prep_grads
      union select distinct prev_month_end, college_code, level_code, program_code, program_version from prep_otp) a
left join prep_drops c
  on a.prev_month_end=c.prev_month_end
  and a.program_code=c.program_code
  and a.program_version=c.program_version
left join prep_t2t d
  on a.prev_month_end=d.prev_month_end
  and a.program_code=d.program_code
  and a.program_version=d.program_version
left join prep_grads e
  on a.prev_month_end=e.prev_month_end
  and a.program_code=e.program_code
  and a.program_version=e.program_version
left join prep_otp o
  on a.prev_month_end=o.prev_month_end
  and a.program_code=o.program_code
  and a.program_version=o.program_version;
select * from BK_STUD_PROG_MONTH;

