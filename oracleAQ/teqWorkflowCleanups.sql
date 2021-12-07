  set cloudconfig ./oracleAQ/network/admin/wallet.zip
--connect DBUSER/"&password"@AQDATABASE_TP ;
connect DBUSER/"WelcomeAQ1234"@AQDATABASE_TP ;
/
--Clean up all objects related to the user
Execute DBMS_AQADM.STOP_QUEUE ( queue_name => 'plsql_userTEQ'); 
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_userTEQ',force=> TRUE);

--Cleans up all objects related to the deliverer
Execute DBMS_AQADM.STOP_QUEUE ( queue_name      => 'plsql_deliveryTEQ');   
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_deliveryTEQ',force=> TRUE);

--Cleans up all objects related to the application
Execute DBMS_AQADM.STOP_QUEUE ( queue_name     => 'plsql_appTEQ');  
Execute DBMS_AQADM.drop_transactional_event_queue(queue_name =>'plsql_appTEQ',force=> TRUE);

--Clean up object type */
DROP TYPE Message_typeTEQ;