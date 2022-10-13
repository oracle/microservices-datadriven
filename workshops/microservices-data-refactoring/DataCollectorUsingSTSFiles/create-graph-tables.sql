-- Copyright (c) 2022, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

drop table tableset_tables;
drop table table_map;

create table tableset_tables 
( table_set_name       varchar2(128)
, schema               varchar2(128)
, table_name           varchar2(128)
, total_sql            number(10)
, total_executions     number(10)
, tables_joined        number(10));

create table table_map 
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
