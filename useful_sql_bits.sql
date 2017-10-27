/****ORACLE is EXTREMELY case-sensitive for names of tables/columns****/

--find all columns with a name sort of like this...
SELECT t.Table_Name AS table_name,
c.Column_Name AS column_name
FROM sys.All_Tables t
INNER JOIN sys.all_tab_columns c ON T.Table_Name = C.Table_Name
WHERE C.Column_Name LIKE '%DENO%' --change here as needed -- leave the '%' unless you are searching for the beginning or end of the string
ORDER BY T.Table_Name;

--all columns from a specific table -- includes nullable
SELECT 
t.Column_Name AS column_name, t.nullable
FROM sys.all_tab_columns t
WHERE t.Table_Name = 'ACTIVE_ASMT';

--update based on join -- requires privileges to update sys tables
update  
 (
select c.column_name, c.comments, co.comments as new_comments
from sys.all_col_comments c 
  left outer join (
    select column_name cn, comments 
    from sys.all_col_comments
    where table_name = 'RST_STUDENT'
    )co on c.column_name = co.cn
where c.table_name = 'JO_RST_STUDENT'
and co.comments is not NULL
)cu
set comments = new_comments
;

--find all of the tables or views referenced by a view list
select * from sys.all_dependencies
where type = 'VIEW' 
and referenced_type in ('TABLE','VIEW') --limiting the referenced object type
and name in ('VW_RST_STUDENT','VW_RST_ASSESSMENT') --list of views for which you want the dependencies
order by name
;
