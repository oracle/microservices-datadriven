 
 set cloudconfig ./oracleAQ/network/admin/wallet.zip
--connect DBUSER/"&password"@AQDATABASE_TP ;
connect DBUSER/"WelcomeAQ1234"@AQDATABASE_TP ;
/
--Clean up all objects related to the user 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       => 'plsql_userQueue');  
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       => 'plsql_userQueue');  
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table => 'plsql_userQueueTable');

--Clean up all objects related to the deliverer 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'plsql_deliveryQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'plsql_deliveryQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'plsql_deliveryQueueTable'); 

--Cleans up all objects related to the application 
EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name       =>'plsql_appQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name       =>'plsql_appQueue');   
EXECUTE DBMS_AQADM.DROP_QUEUE_TABLE (queue_table =>'plsql_appQueueTable'); 
 
--Clean up object type */
DROP TYPE message_typ;
select * from ALL_QUEUES where OWNER='DBUSER';
EXIT;