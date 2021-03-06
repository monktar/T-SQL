SELECT @@VERSION
exec sp_readerrorlog 0,1,'Copyright (c)'
--SELECT * FROM sys.dm_os_sys_info;  
SELECT login_time FROM sys.dm_exec_sessions WHERE session_id = 1; 
SELECT start_time from sys.traces where is_default = 1;
SELECT is_auto_create_stats_on, create_date, nAME AS DbnAME FROM sys.databases ORDER BY NAME
SELECT ' last the server is restarted'
SELECT create_date FROM sys.databases WHERE name = 'tempdb';

-- adding up
SELECT DB_NAME(t.dbid) as DbName, OBJECT_NAME(t.objectid),s.plan_handle,  s.TotalExecutionCount,
 t.text,  s.TotalExecutionCount, s.TotalElapsedTime, s.TotalLogicalReads, s.TotalPhysicalReads, s.TotalCPUTimes
FROM
(
 SELECT deqs.plan_handle,
 SUM(deqs.execution_count) AS TotalExecutionCount,
 SUM(deqs.total_elapsed_time) AS TotalElapsedTime,
 SUM(deqs.total_logical_reads) AS TotalLogicalReads,
 SUM(deqs.total_physical_reads) AS TotalPhysicalReads,
 SUM(deqs.total_worker_time) AS TotalCPUTimes
 FROM sys.dm_exec_query_stats AS deqs
 GROUP BY deqs.plan_handle
) AS s
 CROSS APPLY sys.dm_exec_sql_text(s.plan_handle) AS t
 WHERE DB_NAME(t.dbid) = 'iThinkHealth'
ORDER BY DbName, s.TotalExecutionCount desc, s.TotalElapsedTime DESC, s.TotalLogicalReads DESC,
 s.TotalPhysicalReads DESC;

--Top resource consuming queries  
select DB_NAME(st.dbid) as DbName, OBJECT_NAME(st.objectid) objectname, sum(execution_count), sum(total_elapsed_time), sum(total_worker_time CPU), sum(total_logical_reads), sum(total_logical_writes,
st.text, qs.last_execution_time, qs.plan_handle
from sys.dm_exec_query_stats as qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  DB_NAME(st.dbid) = DB_NAME()
group by qs.plan_handle
order by execution_count desc, objectname


select top 50 OBJECT_NAME(st.objectid) objectname, sum(execution_count) n
from sys.dm_exec_query_stats as qs cross apply sys.dm_exec_sql_text(sql_handle) st
where  DB_NAME(st.dbid) = 'iThinkHealth' and qs.last_execution_time > '20190101'
group by st.objectid
order by n desc, objectname

select * from sys.dm_exec_query_stats

/****************************************************************************************************************************/
/**************************************** 10. Top resource consuming queries ************************************************/
/****************************************************************************************************************************/
-- bello: How often is it executed

SET NOCOUNT ON   
-- 1 Top 10 SQL statements with high Execution count
print '1. Top 10 SQL statements with high Execution count'
select top 20
    qs.execution_count,
    st.dbid,
    DB_NAME(st.dbid) as DbName,
    st.text
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(sql_handle) st
order by execution_count desc
go


/****************************************************************************************************************************/
/**************************************** 11. Top Duration queries **********************************************************/
/****************************************************************************************************************************/
 --bello based on total_elapsed_time  for completed executions of this plan.

print '2. Top 10 SQL statements with high Duration'
select top 10
    qs.total_elapsed_time,
    st.dbid,
    DB_NAME(st.dbid) as DbName,
    st.text
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(sql_handle) st
order by total_elapsed_time desc
go

/****************************************************************************************************************************/
/**************************************** 12. Top CPU consumption queries ***************************************************/
/****************************************************************************************************************************/
--bello total_worker_time
print '3. Top 10 SQL statements with high CPU consumption'
select top 10
    qs.sql_handle,
    qs.total_worker_time,
    st.dbid,
    DB_NAME(st.dbid) as DbName,
    st.text
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(sql_handle) st
order by total_worker_time desc
go


/****************************************************************************************************************************/
/**************************************** 13. Top Reads consumption queries *************************************************/
/****************************************************************************************************************************/
-- bello  total_logical_reads
print '4. Top 10 SQL statements with high Reads consumption'
select top 10
    qs.total_logical_reads,
    st.dbid,
    DB_NAME(st.dbid) as DbName,
    st.text
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(sql_handle) st
order by total_logical_reads desc
go

/****************************************************************************************************************************/
/**************************************** 14. Top Writes consumption queries ************************************************/
/****************************************************************************************************************************/
-- bello total_logical_writes
print '5. Top 10 SQL statements with high Writes consumption'
select top 100
    qs.total_logical_writes,
    st.dbid,
    DB_NAME(st.dbid) as DbName,
    st.text , OBJECT_NAME(st.objectid) AS [ObjectName]
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(sql_handle) st
order by total_logical_writes desc
go

--bello same as above just where clause and order by change
select top 100
    qs.total_logical_writes,
    st.dbid,
    DB_NAME(st.dbid) as DbName,
    st.text , OBJECT_NAME(st.objectid) AS [ObjectName]
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(sql_handle) st
where  st.text like '%sp_%billin%'
order by [ObjectName]  desc
go

--bello 
select distinct OBJECT_NAME(st.objectid) AS [ObjectName]
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(sql_handle) st
where  OBJECT_NAME(st.objectid) like '%sp_%bill%'
order by [ObjectName]  desc
go
--bello 
select distinct OBJECT_NAME(st.objectid) AS [ObjectName]
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(sql_handle) st
where  OBJECT_NAME(st.objectid) like '%sp_%bill%'
order by [ObjectName]  desc
go
--bello
select top 100
    qs.total_logical_writes,
    st.dbid,
    DB_NAME(st.dbid) as DbName,
    st.text , OBJECT_NAME(st.objectid) AS [ObjectName]
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(sql_handle) st
where text like '%billi%'
order by total_logical_writes desc
go
/****************************************************************************************************************************/
/**************************************** 15. Top excessive compiles/recompiles queries *************************************/
/****************************************************************************************************************************/
-- bello 
-- plan_generation_num	bigint	A sequence number that can be used to distinguish between instances of plans after a recompile.

print '6. Top 10 SQL statements with excessive compiles/recompiles'
select top 10
    qs.plan_generation_num, -- plan_generation_num column indicates the number of times the statements has recompiled.
    st.dbid,
    DB_NAME(st.dbid) as DbName,
    st.text
from sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(sql_handle) as st
order by plan_generation_num desc
go



/****************************************************************************************************************************/
/**************************************** 16. Top consume log space queries *************************************************/
/****************************************************************************************************************************/
-- bello 
-- database_transaction_log_record_count for "Number of log records generated" in the database for the transaction.
print '7. Queries that consume a large amount of log space'
select TOP(10)
    T1.database_id,
    DB_NAME(T1.database_id) as DbName,
    T4.text,
    T1.database_transaction_begin_time,
    T1.database_transaction_state,
    T1.database_transaction_log_bytes_used_system,
    T1.database_transaction_log_bytes_reserved,
    T1.database_transaction_log_bytes_reserved_system,
    T1.database_transaction_log_record_count
from sys.dm_tran_database_transactions T1
join sys.dm_tran_session_transactions T2 on T2.transaction_id = T1.transaction_id
join sys.dm_exec_requests T3 on T3.session_id = T2.session_id
cross apply sys.dm_exec_sql_text(T3.sql_handle) T4
--where 
--T1.database_transaction_state = 4 -- 4 : The transaction has generated log records.
--and 
--T1.database_id = db_id()
order by T1.database_transaction_log_record_count desc
--order by T1.database_transaction_log_bytes_reserved desc
go
--Unused / Missing indexes  
/* 
 Return unused and missing indexes
*/
-- Return unused indexes
-- Note : run this query against target database (not against master database)
print 'Unused indexes list'
select
    DB_NAME() as DbName,
    object_name(I.object_id) as TableName,
    I.name as IndexName,
    I.index_id,
    I.type_desc,
    I.is_primary_key
from sys.indexes I
left join sys.dm_db_index_usage_stats U on U.object_id = I.object_id and U.index_id = I.index_id and U.database_id = DB_ID()
where OBJECTPROPERTY(I.object_id,'IsUserTable') = 1
and U.user_seeks is null
and U.user_scans is null
and U.user_lookups is null
and U.last_user_seek is null
and U.last_user_scan is null
and U.last_user_lookup is null
and U.system_seeks is null
and U.system_scans is null
and U.system_lookups is null
and U.last_system_seek is null
and U.last_system_scan is null
and U.last_system_lookup is null
order by 1
go

-- Return missing indexes
print 'Missing indexes list'
select *
from sys.dm_db_missing_index_details
go





