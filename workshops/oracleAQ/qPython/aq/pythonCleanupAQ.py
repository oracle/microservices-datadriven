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
        DBMS_AQADM.STOP_QUEUE( queue_name  => 'PYTHON_AQ_ADT');  
        DBMS_AQADM.DROP_QUEUE( queue_name  => 'PYTHON_AQ_ADT');  
        DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table   => 'PYTHON_AQ_ADT_Table');

        DBMS_AQADM.STOP_QUEUE( queue_name  =>'PYTHON_AQ_RAW');   
        DBMS_AQADM.DROP_QUEUE( queue_name  =>'PYTHON_AQ_RAW');   
        DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table   =>'PYTHON_AQ_RAW_Table'); 
        
        DBMS_AQADM.STOP_QUEUE( queue_name  =>'PYTHON_AQ_JMS');   
        DBMS_AQADM.DROP_QUEUE( queue_name  =>'PYTHON_AQ_JMS');   
        DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table   =>'PYTHON_AQ_JMS_Table'); 
    END;"""
cursor.execute(dropQuery)
