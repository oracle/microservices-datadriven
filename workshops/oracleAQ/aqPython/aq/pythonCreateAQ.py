 #!/usr/bin/env PYTHON_AQ
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

cursor.execute("CREATE OR REPLACE TYPE PYTHON_AQ_MESSAGE_TYPE AS OBJECT (Title   VARCHAR2(100), Authors VARCHAR2(100),Price   NUMBER(5,2))");

adtQuery="""
   BEGIN
      DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'PYTHON_AQ_ADT_Table',     queue_payload_type  => 'PYTHON_AQ_MESSAGE_TYPE');   
      DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'PYTHON_AQ_ADT',          queue_table         => 'PYTHON_AQ_ADT_Table');  
      DBMS_AQADM.START_QUEUE        ( queue_name     => 'PYTHON_AQ_ADT'); 
   END;"""
cursor.execute(adtQuery)

rawQuery="""
   BEGIN
      DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'PYTHON_AQ_RAW_Table',     queue_payload_type  => 'RAW');   
      DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'PYTHON_AQ_RAW',          queue_table         => 'PYTHON_AQ_RAW_Table');  
      DBMS_AQADM.START_QUEUE        ( queue_name     => 'PYTHON_AQ_RAW'); 
   END;"""
cursor.execute(rawQuery)

jmsQuery="""
   BEGIN
      DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'PYTHON_AQ_JMS_Table',     queue_payload_type => 'SYS.AQ$_JMS_TEXT_MESSAGE');
      DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'PYTHON_AQ_JMS',          queue_table        => 'PYTHON_AQ_JMS_Table');
      DBMS_AQADM.START_QUEUE        ( queue_name     => 'PYTHON_AQ_JMS');
   END;"""
cursor.execute(jmsQuery)

query= "select name, queue_table, dequeue_enabled,enqueue_enabled, sharded, queue_category, recipients from all_queues where OWNER='JAVAUSER' and QUEUE_TYPE<>'EXCEPTION_QUEUE'";
for i  in cursor.execute(query):
    print(i)