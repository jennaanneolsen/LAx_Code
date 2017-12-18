select distinct(student_pidm) from (

select student_pidm, month_end_date, count(distinct(student_id)) as student_ids 
from wgubi.vw_rst_student where (active = 1 or grad = 1) 
--limited to the terms for this analysis
and term_code in (201601,201602,201603,201604,201605,201606,201607,201608,201609,201610,201611,201612,201701,201702,201703,201704,201705)

group by student_pidm, month_end_date having count(distinct(student_id)) > 1
--order by month_end_date desc;

)x;
