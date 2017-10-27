--show all the table/columns and comments
select * from sys.all_col_comments
--optional conditions follow
--where comments is not NULL
--where comments is NULL
--where owner = 'WGUBI'
;

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

--spot check suspicious items
select * from sys.all_col_comments where column_name = 'TERM_END_DATE' and comments is not NULL; 