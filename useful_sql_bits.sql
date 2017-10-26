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
