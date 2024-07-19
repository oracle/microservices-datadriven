# Create Graph Tables

Create metadata tables (Nodes and Edges) and populate the data using data from the SQL Tuning Set created in the previous lab. Compute the affinities based on `JOIN` activity between the tables.

## Task 1: Create Graph Metadata Tables

In this task, we will create a set of metadata tables that we will use to store the information we need to perform community detection in the next lab. We will create a table called `NODES` that will contain a list of all the tables used in the workload capture and how many times each table was accessed and/or participated in a join. A second table called `EDGES` is used to store the affinities between pairs of tables. Later, when we create a graph, the first table will describe the vertices, and the second table will define the edges.

1. Create the graph metadata tables by running the following statements - make sure you run these from `YOUR` login SQL Worksheet (not the `ADMIN` user's worksheet):

    ```sql
    drop table edges;
    drop table nodes;

    create table nodes 
    ( table_set_name       varchar2(128)
    , schema               varchar2(128)
    , table_name           varchar2(128)
    , total_sql            number(10)
    , total_executions     number(10)
    , tables_joined        number(10));

    create table edges 
    ( table_set_name       varchar2(128)
    , table1               varchar2(128)
    , schema1              varchar2(128)
    , table2               varchar2(128)
    , schema2              varchar2(128)
    , join_count           number(10)
    , join_executions      number(10)
    , static_coefficient   decimal(10,5)
    , dynamic_coefficient  decimal(10,5)
    , total_affinity       decimal(10,5));
    ```


These two tables, `nodes` and `edges` are designed to store information about tables, their relationships (joins), and various metrics related to SQL statements and executions involving these tables.

The `nodes` table stores information about individual tables, such as their names, schemas, and metrics like the total number of SQL statements and executions involving each table.

The `edges` table stores information about join relationships between pairs of tables, including the table names, schemas, join counts, execution counts, and various coefficient and affinity values related to the join relationships.

These tables are used for identifying frequently joined tables and understanding the relationships and dependencies between tables in a database schema. 


2\. In this step, we will populate the `NODES` table, which will become the vertices in our graph. Execute the following commands to populate the table:

```sql
truncate table nodes;

insert into nodes (table_set_name, schema, table_name, total_sql, total_executions) 
select table_set_name, table_owner, table_name, count(distinct sql_id), sum(executions)
from ( 
    select distinct table_set_name, table_owner, table_name, sql_id, executions 
    from (
        select 'MY_SQLTUNE_DATASET_NAME' table_set_name,
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
            where p.object_name=i.index_name(+) 
            and sqlset_name='MY_SQLTUNE_DATASET_NAME'
            and object_owner = upper('USER_NAME')
        ) v  
    )
) 
group by table_set_name, table_owner, table_name
having table_name is not null;
```

In summary, this SQL code populates the `nodes` table with data derived from the `DBA_SQLSET_PLANS` and `ALL_INDEXES` views, specifically for the SQL Tuning Set named `MY_SQLTUNE_DATASET_NAME` and the schema `USER_NAME`. It calculates the total number of distinct SQL statements (`total_sql`) and the total number of executions (`total_executions`) for each table involved in the SQL Tuning Set, and inserts these values into the `nodes` table along with the table set name, schema, and table name.


3\. Create a helper view that we will use in the affinity calculation. Execute the following command to create the view:

```sql
create view tableset_sql as 
    select distinct table_name, sql_id 
    from (
        select 'MY_SQLTUNE_DATASET_NAME' table_set_name,
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
            where p.object_name=i.index_name(+) 
            and sqlset_name='MY_SQLTUNE_DATASET_NAME' 
            and object_owner = 'USER_NAME'
        ) v
    )
```
The resulting `tableset_sql` view contains distinct combinations of `table_name` and `sql_id` for the tables involved in the SQL Tuning Set named `MY_SQLTUNE_DATASET_NAME` and the schema `USER_NAME`. This view can be useful for analyzing the relationships between tables and SQL statements within the SQL Tuning Set and for performing further queries or analysis on the data.


Node populated. View created. Create the EDGES Table.

## Task 2: Compute Affinities and Populate Edge Table

1. Create the stored procedure to compute the affinities between tables. This procedure reads the information from the SQL Tuning Set and calculates the affinity between tables based on how many times they are used in SQL statements together and how they are used. The procedure does the following:

    For each table in the set that we are interested in and was accessed during the workload capture:
    * Get a list of the SQL statements that used that table, either by reading an index or the table itself
    * For each table that table was joined with, i.e., each pair of tables, work out how many times that pair were joined,
    * Work out what fraction of statements this pair was joined in
    * Apply weights for joins and executions (50% each) and calculate the total affinity between the tables,
    * Work out how many other tables it was joined to in total

    After running this procedure, we have data similar to this in the `EDGES` table (some rows and columns omitted):

    | TABLE1 | TABLE2 |  JOIN_COUNT | JOIN_EXECUTIONS | STATIC_COEFFICIENT | DYNAMIC_COEFFICIENT | TOTAL_AFFINITY 
    | --- | --- | --- | --- | --- | --- | --- 
    | STUDENTS	| COURSES	| 2	| 110	| 0.33333	| 0.45643	| 0.39488
    | STUDENTS	| ENROLLMENTS	| 2	| 120	| 0.5	| 0.52174 |	0.51087
    | FACULTY	| ROLES	| 1	| 10	| 0.09091	| 0.15385	| 0.12238


    The Procedure below computes the following affinity metrics

    **Compute Affinity Metrics**: For each table, the procedure performs the following calculations:
    - Calculates the total number of SQL statements (`all_sql`) and total number of executions (`all_executions`) for the current table and the table it is joined with.
    - Counts the number of distinct SQL statements (`join_count`) and the total number of executions (`join_executions`) where the current table and the other table are joined.
    - Computes the "static coefficient" as the ratio of `join_count` to `all_sql - join_count`.
    - Computes the "dynamic coefficient" as the ratio of `join_executions` to `all_executions - join_executions`.
    - Calculates the `total affinity` as the average of the static and dynamic coefficients.


   Modify MY_SQLTUNE_DATASET_NAME and USER_NAME for your database and Execute the following statements to create the procedure:

    ```sql
    create or replace procedure compute_affinity as
    cursor c is
    select table_name, schema from nodes;
    tblnm varchar2(128);
    ins_sql varchar2(4000);
    upd_sql varchar2(4000);
    begin
        for r in c loop
            ins_sql:= q'{
                insert into USER_NAME.edges 
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
                    'MY_SQLTUNE_DATASET_NAME' table_set_name,
                    tbl1, 
                    'MY_SQLTUNE_DATASET_NAME', 
                    tbl2, 
                    'MY_SQLTUNE_DATASET_NAME', 
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
                            from nodes 
                            where table_name=v2.tbl1 
                            or table_name=v2.tbl2 ) all_sql,
                        (select sum(total_executions) 
                            from nodes 
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
                                where sqlset_name='MY_SQLTUNE_DATASET_NAME' 
                                and object_owner=upper('USER_NAME') 
                                and s.object_name = i.index_name(+) 
                                and sql_id in (
                                    select distinct sql_id 
                                    from dba_sqlset_plans 
                                    where sqlset_name='MY_SQLTUNE_DATASET_NAME' 
                                    and object_name='}'||r.table_name||q'{' 
                                    and  object_owner=upper('USER_NAME')
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
                update USER_NAME.nodes 
                set tables_joined=(select count(distinct table_name) 
                from (
                    select 
                        'MY_SQLTUNE_DATASET_NAME' table_set_name,
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
                        and sqlset_name='MY_SQLTUNE_DATASET_NAME' 
                        and sql_id in (
                            select sql_id 
                            from tableset_sql 
                            where table_name='}'||r.table_name||q'{') 
                            and object_owner = upper('USER_NAME')
                        ) v
                    )
                ) where table_name ='}' || r.table_name || q'{'
            }';
            execute immediate upd_sql;
        end loop;

    end;
    /
    ```

	**Procedure `COMPUTE_AFFINITY_TKDRA compiled`** is the expected output.

     this stored procedure is part of a system that analyzes the relationships and affinities between tables in a database, based on the SQL statements that access those tables. The computed affinity metrics are stored in the `USER_NAME.edges` table, and the number of joined tables is updated in the `USER_NAME.nodes` table

2. Run the procedure to compute affinities.

    ```text
    exec compute_affinity();
    ```

    This may take a few minutes to complete. **PL/SQL procedure successfully completed** is the expected output. 
	Once it is done, we can see the output in the `EDGE` table, For example:

    ```sql
    select * from edges where table1 = 'STUDENTS';
    ```

3. Add the constraints for the newly created tables, where TABLE1 and TABLE2 of EDGES table are foreign keys referencing the TABLE_NAME column of the NODES table.
	```sql
	ALTER TABLE NODES ADD PRIMARY KEY (TABLE_NAME);

	ALTER TABLE EDGES ADD TABLE_MAP_ID NUMBER;
	UPDATE EDGES SET TABLE_MAP_ID = ROWNUM;
	COMMIT;

	ALTER TABLE EDGES ADD PRIMARY KEY (TABLE_MAP_ID);
	ALTER TABLE EDGES MODIFY TABLE1 REFERENCES NODES (TABLE_NAME);
	ALTER TABLE EDGES MODIFY TABLE2 REFERENCES NODES (TABLE_NAME);
	COMMIT;
    ```


Congratulations! You have successfully populated the tables used to create the graph.  Next Step, create a graph
