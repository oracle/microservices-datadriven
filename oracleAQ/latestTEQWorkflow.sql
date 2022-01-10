--user and delivery enqueue
DECLARE
    message_properties            DBMS_AQ.message_properties_t;
    message_handle                RAW(16);
    enqueue_options               DBMS_AQ.enqueue_options_t;

    user_dequeue_options          DBMS_AQ.dequeue_options_t; 
    user_message                  Message_typeTEQ;

    deliverer_dequeue_options     DBMS_AQ.dequeue_options_t;  
    deliverer_message             Message_typeTEQ;

    app_dequeue_options           DBMS_AQ.dequeue_options_t; 
    app_message                   Message_typeTEQ;

    update_dequeue_options        DBMS_AQ.dequeue_options_t; 
    update_message                Message_typeTEQ;
    
    otp                           pls_integer;
    orderId                       pls_integer;
    appOTP                        pls_integer;
    status                        VARCHAR2(10);
    --recipients                    DBMS_AQ.aq$_recipient_list_t;

BEGIN
--Step 1
    otp := dbms_random.value(1000,9999);
    orderId := dbms_random.value(10000,99999);

    user_message                           := Message_typeTEQ(orderId,'User', otp, 'PENDING', 'US');
    user_dequeue_options.dequeue_mode      := DBMS_AQ.REMOVE;
    user_dequeue_options.wait              := DBMS_AQ.NO_WAIT;
    user_dequeue_options.navigation        := DBMS_AQ.FIRST_MESSAGE;           
    user_dequeue_options.consumer_name     := 'plsql_userSubscriberTEQ';
  
    DBMS_AQ.ENQUEUE(
        queue_name           => 'plsql_userTEQ',           
        enqueue_options      => enqueue_options,       
        message_properties   => message_properties,     
        payload              => user_message,               
        msgid                => message_handle
        );
        commit;
    DBMS_AQ.DEQUEUE(
        queue_name           => 'plsql_userTEQ',
        dequeue_options      => user_dequeue_options, 
        message_properties   => message_properties, 
        payload              => user_message, 
        msgid                => message_handle
        );
        commit;
    DBMS_OUTPUT.PUT_LINE ('USER MESSAGE       -        ' || 'ORDERID: ' ||  user_message.ORDERID || ', USERNAME: ' || user_message.USERNAME || ', OTP: ' || user_message.OTP);  
--Step 1.1
  INSERT INTO USERDETAILSTEQ VALUES(user_message.ORDERID, user_message.USERNAME, user_message.OTP, user_message.DELIVERY_STATUS, user_message.DELIVERY_LOCATION);

--Step 2
    --Deliverer will not have OTP
    deliverer_message                       := Message_typeTEQ(user_message.ORDERID, user_message.USERNAME, 0, user_message.DELIVERY_STATUS, user_message.DELIVERY_LOCATION);
    deliverer_dequeue_options.dequeue_mode  := DBMS_AQ.REMOVE;
    deliverer_dequeue_options.wait          := DBMS_AQ.NO_WAIT;
    deliverer_dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;           
    deliverer_dequeue_options.consumer_name := 'plsql_deliverySubscriberTEQ';
    DBMS_AQ.ENQUEUE(
        queue_name           => 'plsql_deliveryTEQ',           
        enqueue_options      => enqueue_options,       
        message_properties   => message_properties,     
        payload              => deliverer_message,               
        msgid                => message_handle
        );
        commit;
    DBMS_AQ.DEQUEUE(
        queue_name           => 'plsql_deliveryTEQ', 
        dequeue_options      => deliverer_dequeue_options, 
        message_properties   => message_properties, 
        payload              => deliverer_message, 
        msgid                => message_handle
        );
        commit;
    DBMS_OUTPUT.PUT_LINE ('DELIVERER MESSAGE  -        ' || 'ORDERID: ' ||  deliverer_message.ORDERID || ', USERNAME: ' || deliverer_message.USERNAME || ', OTP: ' || deliverer_message.OTP);  

--Step 3:
    app_message                             := Message_typeTEQ(deliverer_message.ORDERID, deliverer_message.USERNAME, user_message.OTP, deliverer_message.DELIVERY_STATUS, deliverer_message.DELIVERY_LOCATION);
    app_dequeue_options.dequeue_mode        := DBMS_AQ.REMOVE;
    app_dequeue_options.wait                := DBMS_AQ.NO_WAIT;
    app_dequeue_options.navigation          := DBMS_AQ.FIRST_MESSAGE;           
    app_dequeue_options.consumer_name       := 'plsql_appSubscriberTEQ';
    DBMS_AQ.enqueue(
        queue_name           => 'plsql_appTEQ',           
        enqueue_options      => enqueue_options,       
        message_properties   => message_properties,     
        payload              => app_message,               
        msgid                => message_handle
        );
        commit;
    DBMS_AQ.DEQUEUE(
        queue_name           => 'plsql_appTEQ', 
        dequeue_options      => app_dequeue_options, 
        message_properties   => message_properties, 
        payload              => app_message, 
        msgid                => message_handle
        );
        commit;
    DBMS_OUTPUT.PUT_LINE ('APPLICATION MESSAGE-        ' || 'ORDERID: ' ||  app_message.ORDERID || ', USERNAME: ' || app_message.USERNAME || ', OTP: ' || app_message.OTP);  

--Step 4:
    --v2 use recepient list(user, deliverer) and equeue by app while dequeue by (user and deliverer). 
    SELECT OTP INTO appOTP FROM USERDETAILSTEQ WHERE ORDERID=app_message.ORDERID and DELIVERY_STATUS<>'DELIVERED';

   IF appOTP= user_message.OTP THEN
        -- update delivery status
        UPDATE USERDETAILSTEQ SET DELIVERY_STATUS = 'DELIVERED' WHERE ORDERID=app_message.ORDERID;
        DBMS_OUTPUT.PUT_LINE ('------------------------------');
        DBMS_OUTPUT.PUT_LINE ('OTP VERIFICATION SUCCESS...!!!');
        DBMS_OUTPUT.PUT_LINE ('------------------------------');
   ELSE 
        UPDATE USERDETAILSTEQ SET DELIVERY_STATUS = 'FAILED' WHERE ORDERID=app_message.ORDERID;
        DBMS_OUTPUT.PUT_LINE ('-----------------------------');
        DBMS_OUTPUT.PUT_LINE ('OTP VERIFICATION FAILED...!!!');
        DBMS_OUTPUT.PUT_LINE ('-----------------------------');
   END IF;
    SELECT DELIVERY_STATUS INTO status FROM USERDETAILSTEQ WHERE ORDERID=app_message.ORDERID;
    COMMIT;

    update_message                           := Message_typeTEQ(app_message.ORDERID, app_message.USERNAME, app_message.OTP, status, app_message.DELIVERY_LOCATION);
    update_dequeue_options.wait              := DBMS_AQ.NO_WAIT;
    update_dequeue_options.dequeue_mode      := DBMS_AQ.REMOVE;
    update_dequeue_options.navigation        := DBMS_AQ.FIRST_MESSAGE;           

    --Updating Deliverer
    update_dequeue_options.consumer_name := 'plsql_deliverySubscriberTEQ';
    DBMS_AQ.ENQUEUE(
        queue_name           => 'plsql_deliveryTEQ',           
        enqueue_options      => enqueue_options,       
        message_properties   => message_properties,     
        payload              => update_message,               
        msgid                => message_handle
        );
        commit;
    DBMS_AQ.DEQUEUE(
        queue_name           => 'plsql_deliveryTEQ', 
        dequeue_options      => update_dequeue_options, 
        message_properties   => message_properties, 
        payload              => update_message, 
        msgid                => message_handle
        );
        commit;
    DBMS_OUTPUT.PUT_LINE ('UPDATE DELIVERER MESSAGE-   ' || 'ORDERID: ' ||  update_message.ORDERID || ', USERNAME: ' || update_message.USERNAME || ', DELIVERY_STATUS: ' || update_message.DELIVERY_STATUS);  

   --updating user
    update_dequeue_options.consumer_name       := 'plsql_userSubscriberTEQ';
    DBMS_AQ.ENQUEUE(
        queue_name           => 'plsql_userTEQ',           
        enqueue_options      => enqueue_options,       
        message_properties   => message_properties,     
        payload              => update_message,               
        msgid                => message_handle
        );
        commit;
    DBMS_AQ.DEQUEUE(
        queue_name          => 'plsql_userTEQ',
        dequeue_options     => update_dequeue_options, 
        message_properties  => message_properties, 
        payload             => update_message, 
        msgid               => message_handle
        );
        commit;
    DBMS_OUTPUT.PUT_LINE ('UPDATE USER MESSAGE     -   ' || 'ORDERID: ' ||  update_message.ORDERID || ', USERNAME: ' || update_message.USERNAME || ', DELIVERY_STATUS: ' || update_message.DELIVERY_STATUS);  
END;
/
EXIT;