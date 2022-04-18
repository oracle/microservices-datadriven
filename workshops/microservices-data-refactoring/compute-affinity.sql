-- Copyright (c) 2022, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

create or replace procedure compute_affinity_tkdra as
cursor c is
select table_name, schema from tableset_tables;
tblnm varchar2(128);
ins_sql varchar2(4000);
upd_sql varchar2(4000);
begin
    for r in c loop
        ins_sql:= q'{
            insert into tkdradata.table_map 
            ( table_set_name
            , table1
            , schema1
            , table2
            , schema2
            , join_count
            , join_executions
            , static_coefficient
            , dynamic_coefficient
            , total_affinity) 
            select 
                'tkdradata' table_set_name,
                tbl1, 
                'tkdradata', 
                tbl2, 
                'tkdradata', 
                join_count, 
                join_executions, 
                round(join_count/(all_sql-join_count),5) static_coefficient, 
                round(join_executions/(all_executions-join_executions),5) dynamic_coefficient, 
                (round(join_count/(all_sql-join_count),5)*0.5 + 
                 round(join_executions/(all_executions-join_executions),5)*0.5) total_affinity
            from (
                select 
                    v2.tbl1, 
                    v2.tbl2, 
                    (select sum(total_sql) 
                        from tableset_tables 
                        where table_name=v2.tbl1 
                        or table_name=v2.tbl2 ) all_sql,
                    (select sum(total_executions) 
                        from tableset_tables 
                        where table_name=v2.tbl1 
                        or table_name=v2.tbl2 ) all_executions,
                    v2.join_count, 
                    v2.join_executions 
                from (
                    select 
                        v1.tbl1, 
                        v1.tbl2, 
                        count(distinct v1.sql_id) join_count, 
                        sum(v1.executions) join_executions 
                    from (
                        select distinct 
                            v.tbl1, 
                            case when v.operation='INDEX' then v.TABLE_NAME  
                                when v.operation='TABLE ACCESS' then v.tbl2 
                                else NULL end tbl2,
                            sql_id,
                            executions 
                        from ( 
                            select 
                                '}'||r.table_name||q'{' tbl1, 
                                s.object_name tbl2, 
                                i.table_name table_name, 
                                sql_id, 
                                operation, 
                                executions 
                            from dba_sqlset_plans s, all_indexes i 
                            where sqlset_name='tkdradata' 
                            and object_owner=upper('tkdradata') 
                            and s.object_name = i.index_name(+) 
                            and sql_id in (
                                select distinct sql_id 
                                from dba_sqlset_plans 
                                where sqlset_name='tkdradata' 
                                and object_name='}'||r.table_name||q'{' 
                                and  object_owner=upper('tkdradata')
                            ) 
                        ) v 
                    ) v1  
                    group by v1.tbl1, v1.tbl2   
                    having v1.tbl2 is not null 
                    and v1.tbl1 <> v1.tbl2 
                ) v2 
            )
        }';
        execute immediate ins_sql;

        upd_sql:= q'{
            update tkdradata.tableset_tables 
            set tables_joined=(select count(distinct table_name) 
            from (
                select 
                    'tkdradata' table_set_name,
                    case when v.operation='INDEX' then v.TABLE_NAME 
                         when v.operation='TABLE ACCESS' then v.object_name 
                         else NULL end table_name,
                    v.object_owner as table_owner,
                    v.sql_id, 
                    v.executions 
                from ( 
                    select 
                        p.object_name, 
                        p.operation, 
                        p.object_owner, 
                        p.sql_id, 
                        p.executions, 
                        i.table_name 
                    from dba_sqlset_plans p, all_indexes i 
                    where p.object_name=i.index_name(+) 
                    and sqlset_name='tkdradata' 
                    and sql_id in (
                        select sql_id 
                        from tableset_sql 
                        where table_name='}'||r.table_name||q'{') 
                        and object_owner = upper('tkdradata')
                    ) v
                )
            ) where table_name ='}' || r.table_name || q'{'
        }';
        execute immediate upd_sql;
    end loop;

end;
/


