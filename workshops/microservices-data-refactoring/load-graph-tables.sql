-- Copyright (c) 2022, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

truncate table tableset_tables;

insert into tableset_tables (table_set_name, schema, table_name, total_sql, total_executions) 
select table_set_name, table_owner, table_name, count(distinct sql_id), sum(executions)
from ( 
    select distinct table_set_name, table_owner, table_name, sql_id, executions 
    from (
        select   'tkdradata' table_set_name,
            case when v.operation='INDEX' then v.TABLE_NAME
                when v.operation='TABLE ACCESS' then v.object_name
                else NULL end table_name,
            v.object_owner as table_owner,
            v.sql_id,
            v.executions
        from (
            select p.object_name, p.operation, p.object_owner, 
                p.sql_id, p.executions, i.table_name
            from dba_sqlset_plans p, all_indexes i
            where
            p.object_name=i.index_name(+) and
            sqlset_name='tkdradata' and
            object_owner = upper('tkdradata')
        ) v  
    )
) 
group by table_set_name, table_owner, table_name
having table_name is not null;
