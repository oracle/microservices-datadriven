#!/usr/bin/env python
import os
import logging
from os import environ as env
import cx_Oracle
import oci

connection = cx_Oracle.connect(dsn=env.get('DB_ALIAS'))
cursor = connection.cursor()
dropQuery="""
    BEGIN
        DBMS_AQADM.STOP_QUEUE ( queue_name => 'PYTHON_TEQ_ADT'); 
        DBMS_AQADM.drop_transactional_event_queue(queue_name =>'PYTHON_TEQ_ADT',force=> TRUE);

        DBMS_AQADM.STOP_QUEUE ( queue_name => 'PYTHON_TEQ_RAW'); 
        DBMS_AQADM.drop_transactional_event_queue(queue_name =>'PYTHON_TEQ_RAW',force=> TRUE);

        DBMS_AQADM.STOP_QUEUE ( queue_name => 'PYTHON_TEQ_JMS'); 
        DBMS_AQADM.drop_transactional_event_queue(queue_name =>'PYTHON_TEQ_JMS',force=> TRUE);

        DBMS_AQADM.STOP_QUEUE ( queue_name => 'PYTHON_TEQ_JSON'); 
        DBMS_AQADM.drop_transactional_event_queue(queue_name =>'PYTHON_TEQ_JSON',force=> TRUE);
    END;"""
cursor.execute(dropQuery)
