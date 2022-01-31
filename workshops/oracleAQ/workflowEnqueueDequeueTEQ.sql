CREATE OR REPLACE FUNCTION enqueueDequeue(subscriber varchar2, queueName varchar2, message Message_Typ) RETURN Message_Typ 
IS 
    enqueue_options                   DBMS_AQ.enqueue_options_t;
    message_properties                DBMS_AQ.message_properties_t;
    message_handle                    RAW(16);
    dequeue_options                   DBMS_AQ.dequeue_options_t;
    recipients                        DBMS_AQ.aq$_recipient_list_t;
    messageData                       Message_Typ;

BEGIN
    messageData                       := message;
    recipients(1)                     := sys.aq$_agent(subscriber, NULL, NULL);
    message_properties.recipient_list := recipients;
    dequeue_options.dequeue_mode      := DBMS_AQ.REMOVE;
    dequeue_options.wait              := DBMS_AQ.NO_WAIT;
    dequeue_options.navigation        := DBMS_AQ.FIRST_MESSAGE;           
    dequeue_options.consumer_name     := subscriber;

    DBMS_AQ.ENQUEUE(
        queue_name                    => queueName,           
        enqueue_options               => enqueue_options,       
        message_properties            => message_properties,     
        payload                       => messageData,               
        msgid                         => message_handle);
        COMMIT;

    DBMS_AQ.DEQUEUE(
        queue_name                    => queueName,
        dequeue_options               => dequeue_options, 
        message_properties            => message_properties, 
        payload                       => messageData, 
        msgid                         => message_handle);
        commit;

    RETURN messageData;
END;
/
DECLARE
    userToApplication_message         Message_typ;
    userToDeliverer_message           Message_typ;
    delivererToUser_message           Message_typ;
    delivererToApplication_message    Message_typ;
    applicationToUser_message         Message_typ;
    applicationToDeliverer_message    Message_typ;
    
    otp                               pls_integer;
    orderId                           pls_integer;
    appOTP                            pls_integer;
    status                            varchar2(10);

BEGIN
    orderId := dbms_random.value(10000,99999);
    otp     := dbms_random.value(1000,9999);

-- 1: USER PLACED OREDER ON APPLICATION
    userToApplication_message      := enqueueDequeue('plsql_userAppSubscriber',             'plsql_UserTEQ',         Message_typ(orderId,'User', 0, 'PENDING', 'US'));
    DBMS_OUTPUT.PUT_LINE ('USER ORDER MESSAGE               :  ' || 'ORDERID: ' ||  userToApplication_message.ORDERID || ', USERNAME: ' || userToApplication_message.USERNAME || ', OTP: ' || userToApplication_message.OTP);  

-- 2: APPLICATION CREATES AN USER RECORD
    INSERT INTO USERDETAILS VALUES(userToApplication_message.ORDERID, userToApplication_message.USERNAME, otp, userToApplication_message.DELIVERY_STATUS, userToApplication_message.DELIVERY_LOCATION);

-- 3: APPLICATION SHARES OTP TO USER
    applicationToUser_message       := enqueueDequeue('plsql_appUserSubscriber', 'plsql_ApplicationTEQ', Message_typ(userToApplication_message.ORDERID, userToApplication_message.USERNAME, otp, userToApplication_message.DELIVERY_STATUS, userToApplication_message.DELIVERY_LOCATION));
    DBMS_OUTPUT.PUT_LINE ('APPLICATION TO USER MESSAGE      :  ' || 'ORDERID: ' ||  applicationToUser_message.ORDERID || ', USERNAME: ' || applicationToUser_message.USERNAME || ', OTP: ' || applicationToUser_message.OTP);  

-- 4: APPLICATION SHARES DELIVERY DETAILS TO DELIVERER
    applicationToDeliverer_message  := enqueueDequeue('plsql_appDelivererSubscriber', 'plsql_ApplicationTEQ', Message_typ(applicationToUser_message.ORDERID, applicationToUser_message.USERNAME, 0, applicationToUser_message.DELIVERY_STATUS, applicationToUser_message.DELIVERY_LOCATION));
    DBMS_OUTPUT.PUT_LINE ('APPLICATION TO DELIVERER MESSAGE :  ' || 'ORDERID: ' ||  applicationToDeliverer_message.ORDERID || ', USERNAME: ' || applicationToDeliverer_message.USERNAME || ', OTP: ' || applicationToDeliverer_message.OTP);  

-- 5: User shares OTP to DELIVERER
    userToDeliverer_message         := enqueueDequeue('plsql_userDelivererSubscriber', 'plsql_UserTEQ', Message_typ(applicationToUser_message.ORDERID, applicationToUser_message.USERNAME, applicationToUser_message.OTP, applicationToUser_message.DELIVERY_STATUS, applicationToUser_message.DELIVERY_LOCATION));
    DBMS_OUTPUT.PUT_LINE ('User TO DELIVERER MESSAGE        :  ' || 'ORDERID: ' ||  userToDeliverer_message.ORDERID || ', USERNAME: ' || userToDeliverer_message.USERNAME || ', OTP: ' || userToDeliverer_message.OTP);  

-- 6: DELIVERER TO APPLICATION FOR OTP VERIFICATION
    delivererToApplication_message  := enqueueDequeue('plsql_delivererApplicationSubscriber', 'plsql_DelivererTEQ', Message_typ(userToDeliverer_message.ORDERID, userToDeliverer_message.USERNAME, userToDeliverer_message.OTP, userToDeliverer_message.DELIVERY_STATUS, userToDeliverer_message.DELIVERY_LOCATION));
    DBMS_OUTPUT.PUT_LINE ('DELIVERER TO APPLICATION MESSAGE :  ' || 'ORDERID: ' ||  delivererToApplication_message.ORDERID || ', USERNAME: ' || delivererToApplication_message.USERNAME || ', OTP: ' || delivererToApplication_message.OTP);  

-- 7: APPLICATION VERIFIES OTP WITH USER RECORD AND UPDATE DELIVERY STATUS
    SELECT OTP INTO appOTP FROM USERDETAILS WHERE ORDERID=delivererToApplication_message.ORDERID and DELIVERY_STATUS<>'DELIVERED';

    IF appOTP= delivererToApplication_message.OTP THEN
        UPDATE USERDETAILS SET DELIVERY_STATUS = 'DELIVERED' WHERE ORDERID=delivererToApplication_message.ORDERID;
        DBMS_OUTPUT.PUT_LINE ('------------------------------');
        DBMS_OUTPUT.PUT_LINE ('OTP VERIFICATION SUCCESS...!!!');
        DBMS_OUTPUT.PUT_LINE ('------------------------------');
    ELSE 
        UPDATE USERDETAILS SET DELIVERY_STATUS = 'FAILED'    WHERE ORDERID=delivererToApplication_message.ORDERID;
        DBMS_OUTPUT.PUT_LINE ('-----------------------------');
        DBMS_OUTPUT.PUT_LINE ('OTP VERIFICATION FAILED...!!!');
        DBMS_OUTPUT.PUT_LINE ('-----------------------------');
    END IF;
    SELECT DELIVERY_STATUS INTO status FROM USERDETAILS      WHERE ORDERID=delivererToApplication_message.ORDERID;
    COMMIT;

-- 8: APPLICATION UPDATE DELIVERER TO DELIVER ORDER
    applicationToDeliverer_message  := enqueueDequeue('plsql_appDelivererSubscriber', 'plsql_ApplicationTEQ', Message_typ(delivererToApplication_message.ORDERID, delivererToApplication_message.USERNAME, delivererToApplication_message.OTP, status, delivererToApplication_message.DELIVERY_LOCATION));
    DBMS_OUTPUT.PUT_LINE ('UPDATE DELIVERER MESSAGE         :  ' || 'ORDERID: ' ||  applicationToDeliverer_message.ORDERID || ', USERNAME: ' || applicationToDeliverer_message.USERNAME || ', DELIVERY_STATUS: ' || applicationToDeliverer_message.DELIVERY_STATUS);  

-- 9: APPLICATION UPDATE USER FOR DELIVERED ORDER
    applicationToUser_message  := enqueueDequeue('plsql_appUserSubscriber', 'plsql_ApplicationTEQ', Message_typ(delivererToApplication_message.ORDERID, delivererToApplication_message.USERNAME, otp, status, delivererToApplication_message.DELIVERY_LOCATION));
    DBMS_OUTPUT.PUT_LINE ('UPDATE USER MESSAGE-             :  ' || 'ORDERID: ' ||  applicationToUser_message.ORDERID || ', USERNAME: ' || applicationToUser_message.USERNAME || ', DELIVERY_STATUS: ' || applicationToUser_message.DELIVERY_STATUS);  
END;


