 
 set cloudconfig ./oracleAQ/network/admin/wallet.zip
--connect DBUSER/"&password"@AQDATABASE_TP ;
connect DBUSER/&1@AQDATABASE_TP ;

--Clean up all objects related to the obj type: */
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'objType_classicQueue');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'objType_classicQueue');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'objType_classicQueueTable');

--Clean up all objects related to the RAW type: */
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'rawType_classicQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'rawType_classicQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'rawType_classicQueueTable'); 

--Clean up all objects related to the JSON type: */
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'JSONType_classicQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'JSONType_classicQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'JSONType_classicQueueTable'); 

--Cleans up all objects related to the RAW type: */
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'multiconsumer_rawType_classicQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'multiconsumer_rawType_classicQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'multiconsumer_rawType_classicQueueTable'); 
 
--Clean up object type */
DROP TYPE obj_typ;
/
select * from ALL_QUEUES where OWNER='DBUSER' and QUEUE_TYPE='NORMAL_QUEUE';
/
EXIT;
