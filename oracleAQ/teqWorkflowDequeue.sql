set cloudconfig ./oracleAQ/network/admin/wallet.zip
--connect DBUSER/"&password"@AQDATABASE_TP ;
connect DBUSER/"WelcomeAQ1234"@AQDATABASE_TP ;

--user and delivery enqueue
DECLARE
    app_enqueue_options      DBMS_AQ.enqueue_options_t;
    message_properties       dbms_aq.message_properties_t;
    message_handle           RAW(16);

    user_dequeue_options     DBMS_AQ.dequeue_options_t; 
    user_message             Message_typeTEQ;

    deli_dequeue_options     DBMS_AQ.dequeue_options_t;  
    delivery_message         Message_typeTEQ;

    app_dequeue_options      DBMS_AQ.dequeue_options_t; 
    app_message              Message_typeTEQ;

    appOTP                   pls_integer;

BEGIN
    -- user dequeue browse
    user_dequeue_options.dequeue_mode  := DBMS_AQ.BROWSE;
    user_dequeue_options.wait          := DBMS_AQ.NO_WAIT;
    user_dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;           
    user_dequeue_options.consumer_name := 'plsql_userSubscriberTEQ';
    DBMS_AQ.DEQUEUE(queue_name => 'plsql_userTEQ',    dequeue_options => user_dequeue_options, message_properties => message_properties, payload => user_message, msgid => message_handle);
    DBMS_OUTPUT.PUT_LINE ('User Message: ' || user_message.ORDERID || ' ... ' || user_message.USERNAME || ' ... ' || user_message.OTP);   
    

    -- delivery dequeue remove
    deli_dequeue_options.dequeue_mode  := DBMS_AQ.REMOVE;
    deli_dequeue_options.wait          := DBMS_AQ.NO_WAIT;
    deli_dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;           
    deli_dequeue_options.consumer_name := 'plsql_deliverySubscriberTEQ';
    DBMS_AQ.DEQUEUE(queue_name => 'plsql_deliveryTEQ', dequeue_options => deli_dequeue_options, message_properties => message_properties, payload => delivery_message, msgid => message_handle);
    DBMS_OUTPUT.PUT_LINE ('Delivery Message: ' || delivery_message.ORDERID || ' ... ' || delivery_message.USERNAME || ' ... ' || delivery_message.OTP);   
    
    -- app enqueue after collecting user OTP
    app_message := Message_typeTEQ(user_message.ORDERID, user_message.USERNAME, user_message.OTP, user_message.DELIVERY_STATUS, user_message.DELIVERY_LOCATION);
    DBMS_AQ.enqueue(
        queue_name => 'plsql_appTEQ',           
        enqueue_options      => enqueue_options,       
        message_properties   => message_properties,     
        payload              => app_message,               
        msgid                => message_handle);

    -- app dequeue browse to verify OTP
    app_dequeue_options.dequeue_mode  := DBMS_AQ.BROWSE;
    app_dequeue_options.wait          := DBMS_AQ.NO_WAIT;
    app_dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;           
    app_dequeue_options.consumer_name := 'plsql_appSubscriberTEQ';
    DBMS_AQ.DEQUEUE(queue_name => 'plsql_appTEQ', dequeue_options => app_dequeue_options, message_properties => message_properties, payload => app_message, msgid => message_handle);
    DBMS_OUTPUT.PUT_LINE ('APP Message: ' || app_message.ORDERID || ' ... ' || app_message.USERNAME || ' ... ' || app_message.OTP);   

    -- get OTP from DB
    SELECT OTP INTO appOTP FROM USERDETAILSTEQ WHERE ORDERID=app_message.ORDERID;

    -- verify OTP
    IF appOTP= user_message.OTP THEN
     
        -- update delivery location
        UPDATE USERDETAILSTEQ SET DELIVERY_STATUS = 'DELIVERED' WHERE ORDERID=delivery_message.ORDERID;

        -- user dequeue remove
        user_dequeue_options.dequeue_mode  := DBMS_AQ.REMOVE;
        user_dequeue_options.wait          := DBMS_AQ.NO_WAIT;
        user_dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;           
        user_dequeue_options.consumer_name := 'plsql_userSubscriberTEQ';
        DBMS_AQ.DEQUEUE(queue_name => 'plsql_userTEQ',    dequeue_options => user_dequeue_options, message_properties => message_properties, payload => user_message, msgid => message_handle);
        DBMS_OUTPUT.PUT_LINE ('USER DEQUEUE REMOVED ');   

        -- app dequeue remove
        app_dequeue_options.dequeue_mode  := DBMS_AQ.REMOVE;
        app_dequeue_options.wait          := DBMS_AQ.NO_WAIT;
        app_dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;           
        app_dequeue_options.consumer_name := 'plsql_appSubscriberTEQ';
        DBMS_AQ.DEQUEUE(queue_name => 'plsql_appTEQ', dequeue_options => app_dequeue_options, message_properties => message_properties, payload => app_message, msgid => message_handle);
        DBMS_OUTPUT.PUT_LINE ('APP DEQUEUE REMOVED ');  

    END IF;

END;
EXIT; 

        