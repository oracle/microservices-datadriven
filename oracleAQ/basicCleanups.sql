 
 set cloudconfig ./oracleAQ/network/admin/wallet.zip
--connect DBUSER/"&password"@AQDATABASE_TP ;
connect DBUSER/"WelcomeAQ1234"@AQDATABASE_TP ;
/
--Clean up all objects related to the obj type: */
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'objType_classicQueue');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'objType_classicQueue');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'objType_classicQueue');

--Clean up all objects related to the RAW type: */
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'rawType_classicQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'rawType_classicQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'rawType_classicQueueTable'); 

--Cleans up all objects related to the RAW type: */
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'multiconsumer_rawType_classicQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'multiconsumer_rawType_classicQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'multiconsumer_rawType_classicQueueTable'); 
 
--Clean up object type */
DROP TYPE message_typ;