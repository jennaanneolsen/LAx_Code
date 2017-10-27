--show all the table/columns and comments
select * from sys.all_col_comments
--optional conditions follow
--where comments is not NULL
--where comments is NULL
--where owner = 'WGUBI'
;

--spot check suspicious items
select * from sys.all_col_comments where column_name = 'TERM_END_DATE' and comments is not NULL; 

--NEW Process STAGE 1 -- requires admin access
--columns and comments with single, non NULL comment for the same column name -- 9112 records 10-27-17
SELECT co.Table_Name AS table_name,
co.Column_Name AS column_name,
co.COMMENTS, co_full.comments as comments_stored 
FROM sys.all_col_comments co
join (
  select distinct(column_name) as cname, comments from sys.all_col_comments where comments is not NULL
  )co_full on co.column_name = co_full.cname 
left outer   join (
  select column_name, count(distinct(comments)) from sys.all_col_comments group by column_name having count(distinct(comments)) > 1
  )c2 on co.column_name = c2.column_name   
where co.comments is NULL --comments not currently populated
and c2.column_name is NULL; --only ONE non NULL comment value


--STAGE 2  -- requires admin review and access
--review the results & determine what to do next:
--merge comments into new comment?
--master comment replaces NULL and not NULL?
--handle individually 
--column names with more than 1 distinct comment value (including NULL)
select c.* from sys.all_col_comments c
  join (
  select column_name, count(distinct(comments)) from sys.all_col_comments group by column_name having count(distinct(comments)) > 1
  )c2 on c.column_name = c2.column_name 
order by c.column_name, comments; 

--could probably be merged into one master comment
select * from sys.all_col_comments where column_name = 'APPLICATION_ID'; 

--these would likely need to be handled on an individual basis -- so 'STATUS' should be handled individually
select * from sys.all_col_comments where column_name = 'STATUS'; 

--STAGE 3 -- metadata in RDBMS
--if added in Data Modeler and DDL generated it looks like this:
COMMENT ON COLUMN wgubiselect.jo_rst_student.active IS
    'counter for an active student in a time period; 1, 0 or NULL';
--for this stage need a definite process:
/*
1. open Data Modeler and connect to the database
2. select the tables you are defining
3. enter the definition
4. end of work period -- generate & run DDL

(possible alternate process)
select table in connections list
click the edit table button
add comments to columns 
*/

/* --previous version
--columns and comments (possibly constraint based on column name)...
SELECT t.Table_Name AS table_name,
c.Column_Name AS column_name,
co.COMMENTS, co_full.comments as comments_stored 
FROM sys.All_Tables t
JOIN sys.all_tab_columns c ON T.Table_Name = C.Table_Name
JOIN sys.all_col_comments co on c.TABLE_NAME = co.TABLE_NAME and c.COLUMN_NAME = co.COLUMN_NAME
left outer join (
  select distinct(column_name) as cname, comments from sys.all_col_comments where comments is not NULL
  )co_full on co.column_name = co_full.cname 
where co.comments is NULL --comments not currently populated
and co_full.comments is not NULL --comments populated for that field name in another table
--and c.column_name not in ('STATUS', 'CREATED','MODIFIED','OWNER','TABLE_NAME','NAME');  --exclude column names where the comment might not be consistent
and c.column_name like 'TERM_END%'; --specify by column_name
*/

