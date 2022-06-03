#!/usr/bin/env python
import os
import logging
from os import environ as env
import cx_Oracle
import threading
import time
import oci
import base64

connection = cx_Oracle.connect(dsn=env.get('DB_ALIAS'))
cursor = connection.cursor()

cursor.execute("CREATE OR REPLACE TYPE PYTHON_TEQ_MESSAGE_TYPE AS OBJECT (Title   VARCHAR2(100), Authors VARCHAR2(100),Price   NUMBER(5,2))");

adtQuery="""
  BEGIN
    DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
        queue_name         =>'PYTHON_TEQ_ADT',
        storage_clause     =>null, 
        multiple_consumers =>true, 
        max_retries        =>10,
        comment            =>'ObjectType for TEQ', 
        queue_payload_type =>'PYTHON_TEQ_MESSAGE_TYPE', 
        queue_properties   =>null, 
        replication_mode   =>null);
    DBMS_AQADM.START_QUEUE (queue_name=> 'PYTHON_TEQ_ADT', enqueue =>TRUE, dequeue=> True); 
    COMMIT;
        DBMS_AQADM.add_subscriber(queue_name => 'PYTHON_TEQ_ADT', subscriber => sys.aq$_agent('PYTHON_TEQ_SUBSCIBER_ADT', null ,0)); END;"""
cursor.execute(adtQuery)

rawQuery = """
    DECLARE
        subscriber sys.aq$_agent;
    BEGIN
        DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
            queue_name         =>'PYTHON_TEQ_RAW',
            storage_clause     =>null, 
            multiple_consumers =>true, 
            max_retries        =>10,
            comment            =>'TEQ samples using PYTHON', 
            queue_payload_type =>'RAW', 
            queue_properties   =>null, 
            replication_mode   =>null);
        DBMS_AQADM.START_QUEUE (queue_name=>'PYTHON_TEQ_RAW', enqueue =>TRUE, dequeue=> True); 
    COMMIT;
        DBMS_AQADM.add_subscriber(queue_name => 'PYTHON_TEQ_RAW', subscriber => sys.aq$_agent('PYTHON_TEQ_SUBSCIBER_RAW', null ,0)); END;"""
cursor.execute(rawQuery)

jsonQuery = """
    DECLARE
        subscriber sys.aq$_agent;
    BEGIN
        DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
            queue_name         =>'PYTHON_TEQ_JSON',
            storage_clause     =>null, 
            multiple_consumers =>true, 
            max_retries        =>10,
            comment            =>'TEQ samples using PYTHON', 
            queue_payload_type =>'JSON', 
            queue_properties   =>null, 
            replication_mode   =>null);
        DBMS_AQADM.START_QUEUE (queue_name=>'PYTHON_TEQ_JSON', enqueue =>TRUE, dequeue=> True); 
    COMMIT;
        DBMS_AQADM.add_subscriber(queue_name => 'PYTHON_TEQ_JSON', subscriber => sys.aq$_agent('PYTHON_TEQ_SUBSCIBER_JSON', null ,0)); END;"""
cursor.execute(jsonQuery)

jmsQuery = """
    DECLARE
        subscriber sys.aq$_agent;
    BEGIN
        DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
            queue_name         =>'PYTHON_TEQ_JMS',
            storage_clause     =>null, 
            multiple_consumers =>true, 
            max_retries        =>10,
            comment            =>'TEQ samples using PYTHON', 
            queue_payload_type =>'JMS', 
            queue_properties   =>null, 
            replication_mode   =>null);
        DBMS_AQADM.START_QUEUE (queue_name=>'PYTHON_TEQ_JMS', enqueue =>TRUE, dequeue=> True); 
    COMMIT;
        DBMS_AQADM.add_subscriber(queue_name => 'PYTHON_TEQ_JMS', subscriber => sys.aq$_agent('PYTHON_TEQ_SUBSCIBER_JMS', null ,0)); END;"""
cursor.execute(jmsQuery)

query= "select name, queue_table, dequeue_enabled,enqueue_enabled, sharded, queue_category, recipients from all_queues where OWNER='JAVAUSER' and QUEUE_TYPE<>'EXCEPTION_QUEUE'";
for i  in cursor.execute(query):
    print(i)