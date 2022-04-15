-- Copyright (c) 2022, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

alter table tableset_tables 
add constraint pk  primary key ( table_name );

alter table table_map
add constraint t1fk foreign key ( table1 ) 
references tableset_tables ( table_name );

alter table table_map
add constraint t2fk foreign key ( table2 ) 
references tableset_tables ( table_name );

alter table table_map 
add constraint pk2 primary key ( table1, table2 );