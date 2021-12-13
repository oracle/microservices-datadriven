
set cloudconfig ./oracleAQ/network/admin/wallet.zip
connect DBUSER/&1@AQDATABASE_TP ;
/
--user and delivery enqueue
DECLARE
    enqueue_options     dbms_aq.enqueue_options_t;
    message_properties  dbms_aq.message_properties_t;
    message_handle      RAW(16);
    user_message        Message_typ;
    delivery_message    Message_typ;
    otp                 pls_integer;
    orderId             pls_integer;

BEGIN
    otp := dbms_random.value(1000,9999);
    orderId := dbms_random.value(10000,99999);

    user_message := Message_typ(orderId,'User', otp, 'PENDING', 'US');
    --Deliverer will not have OTP
    delivery_message := Message_typ(orderId, 'User', 0, 'PENDING', 'US');

    INSERT INTO USERDETAILS VALUES(orderId,'User', otp, 'PENDING', 'US');

    dbms_aq.enqueue(
        queue_name => 'plsql_userQueue',           
        enqueue_options      => enqueue_options,       
        message_properties   => message_properties,     
        payload              => user_message,               
        msgid                => message_handle);
    
    dbms_aq.enqueue(
        queue_name => 'plsql_deliveryQueue',           
        enqueue_options      => enqueue_options,       
        message_properties   => message_properties,     
        payload              => delivery_message,               
        msgid                => message_handle);
    COMMIT;
END;
/
EXIT;