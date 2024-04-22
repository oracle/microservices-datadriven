-- Copyright (c) 2022, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

begin
    for i in 1..100 loop
        execute immediate
            'create table dra_' || i || '
            ( col1 varchar2(256) )
            ';
    end loop;
end;
/