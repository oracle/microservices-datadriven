
set cloudconfig ./oracleAQ/network/admin/wallet.zip
--connect DBUSER/"&password"@AQDATABASE_TP ;
connect DBUSER/"WelcomeAQ1234"@AQDATABASE_TP ;

--user and delivery enqueue
DECLARE
    enqueue_options     dbms_aq.enqueue_options_t;
    message_properties  dbms_aq.message_properties_t;
    message_handle      RAW(16);
    user_message        Message_typeTEQ;
    delivery_message    Message_typeTEQ;
    otp                 pls_integer;
    orderId             pls_integer;

BEGIN
    otp := dbms_random.value(1000,9999);
    orderId := dbms_random.value(10000,99999);

    user_message := Message_typeTEQ(orderId,'User', otp, 'PENDING', 'US');
    --Deliverer will not have OTP
    delivery_message := Message_typeTEQ(orderId, 'User', 0, 'PENDING', 'US');

    INSERT INTO USERDETAILSTEQ VALUES(orderId,'User', otp, 'PENDING', 'US');
    dbms_aq.enqueue(
        queue_name => 'plsql_userTEQ',           
        enqueue_options      => enqueue_options,       
        message_properties   => message_properties,     
        payload              => user_message,               
        msgid                => message_handle);
    
    dbms_aq.enqueue(
        queue_name => 'plsql_deliveryTEQ',           
        enqueue_options      => enqueue_options,       
        message_properties   => message_properties,     
        payload              => delivery_message,               
        msgid                => message_handle);
    COMMIT;
END;
/
EXIT;