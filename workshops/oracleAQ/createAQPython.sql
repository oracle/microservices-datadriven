 CREATE OR REPLACE TYPE ADT_BOOK AS OBJECT (
    Title   VARCHAR2(100),
    Authors VARCHAR2(100),
    Price   NUMBER(5,2)
);
/
--Python ADT queue 
BEGIN
   DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'PYTHON_ADT_QTable',     queue_payload_type  => 'ADT_BOOK');   
   DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'PYTHON_ADT_Q',          queue_table         => 'PYTHON_ADT_QTable');  
   DBMS_AQADM.START_QUEUE        ( queue_name     => 'PYTHON_ADT_Q'); 
END;
/
--Python RAW queue 
BEGIN
   DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'PYTHON_RAW_QTable',     queue_payload_type  => 'RAW');   
   DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'PYTHON_RAW_Q',          queue_table         => 'PYTHON_RAW_QTable');  
   DBMS_AQADM.START_QUEUE        ( queue_name     => 'PYTHON_RAW_Q'); 
END;
/ 
--Python JMS queue 
BEGIN
    DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'PYTHON_JMS_QTable',     queue_payload_type => 'SYS.AQ$_JMS_TEXT_MESSAGE');
    DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'PYTHON_JMS_Q',          queue_table        => 'PYTHON_JMS_QTable');
    DBMS_AQADM.START_QUEUE        ( queue_name     => 'PYTHON_JMS_Q');
END;