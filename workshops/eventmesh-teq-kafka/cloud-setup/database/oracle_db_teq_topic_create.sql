-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
set echo on

-- Creating a JMS type sharded queue:
BEGIN
    sys.dbms_aqadm.create_sharded_queue(queue_name=>'$LAB_TEQ_TOPIC', multiple_consumers => TRUE);
    -- sys.dbms_aqadm.set_queue_parameter('$LAB_TEQ_TOPIC', 'SHARD_NUM', 1);
    -- sys.dbms_aqadm.set_queue_parameter('$LAB_TEQ_TOPIC', 'STICKY_DEQUEUE', 1);
    -- sys.dbms_aqadm.set_queue_parameter('$LAB_TEQ_TOPIC', 'KEY_BASED_ENQUEUE', 1);
    sys.dbms_aqadm.start_queue('$LAB_TEQ_TOPIC');
END;
/

--- Create the subscriber agent
DECLARE
    subscriber sys.aq$_agent;
BEGIN
    subscriber := sys.aq$_agent('$LAB_TEQ_TOPIC_SUBSCRIBER', NULL, NULL);
    DBMS_AQADM.ADD_SUBSCRIBER(queue_name => '$LAB_TEQ_TOPIC',   subscriber => subscriber);
END;
/
exit;