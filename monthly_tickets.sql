
-- run this table monthly

drop table BK_TICKETS;
create table BK_TICKETS as
select  
  'SF' as tool,
  concat('https://srm.my.salesforce.com/', substr(ID,1,15)) as ticket_link,
  NAME as ticket_name,
  to_date(DATECLOSED__C) as end_date,
  STATUS__C as status,
  QUEUE__C as assigned_to,
  TYPE__C as type,
  SUBTYPE__C as subtype,
  COLLEGE__C as PDev_Team, 
  WGUCOURSENAME__C as course_number
from wgubi.bi_p_programfeedback
where SUBMITTERROLE__C='Program Development' 
  and WGUCOURSENAME__C is not null

union all

select
  'JIRA' as tool,
  concat('https://projects.wgu.edu/browse/',key) as ticket_link,
  key as ticket_name,
  to_date(full_release) as end_date,
  status as status,
  assignee as assigned_to,
  dev_project_type as type,
  NULL as subtype,
  COLLEGE as PDev_Team, 
  course_code as course_number
from wgubi.VW_STG_JIRA_CPS_IMPORTS;


