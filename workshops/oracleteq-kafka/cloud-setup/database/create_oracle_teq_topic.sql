-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

set echo on
--set serveroutput on size 20000
--set serverout on verify off

declare
  teq_topic      varchar2(30) := '&1' ;
  teq_subscriber varchar2(30) := '&2' ;
  subscriber     sys.aq$_agent;
begin
    if teq_topic is not null and teq_subscriber is not null
    then
        -- Creating a JMS type sharded queue:
        dbms_aqadm.create_sharded_queue(
            queue_name => teq_topic,
            multiple_consumers => TRUE);

        dbms_aqadm.start_queue(teq_topic);

        --- Create the subscriber agent
        subscriber := sys.aq$_agent(teq_subscriber, NULL, NULL);

        dbms_aqadm.add_subscriber(
            queue_name => teq_topic,
            subscriber => subscriber);
    else
        DBMS_OUTPUT.put_line('ERR : at least one of the variables is null !');
    end if;
end;
/
commit;
