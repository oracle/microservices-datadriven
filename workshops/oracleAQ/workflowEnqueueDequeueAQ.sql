SET SERVEROUTPUT ON ;
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
    userToApplication_message      := enqueueDequeueAQ('aq_userAppSubscriber',             'aq_UserQueue',         Message_typ(orderId,'User', 0, 'PENDING', 'US'));
    DBMS_OUTPUT.PUT_LINE ('USER ORDER MESSAGE               :  ' || 'ORDERID: ' ||  userToApplication_message.ORDERID ||  ', OTP: ' || userToApplication_message.OTP);  
    DBMS_OUTPUT.PUT_LINE (' ');
-- 2: APPLICATION CREATES AN USER RECORD
    INSERT INTO USERDETAILS VALUES(userToApplication_message.ORDERID, userToApplication_message.USERNAME, otp, userToApplication_message.DELIVERYSTATUS, userToApplication_message.DELIVERYLOCATION);

-- 3: APPLICATION SHARES OTP TO USER
    applicationToUser_message := enqueueDequeueAQ('aq_appUserSubscriber', 'aq_ApplicationQueue', Message_typ(userToApplication_message.ORDERID, userToApplication_message.USERNAME, otp, userToApplication_message.DELIVERYSTATUS, userToApplication_message.DELIVERYLOCATION));
    DBMS_OUTPUT.PUT_LINE ('APPLICATION TO USER MESSAGE      :  ' || 'ORDERID: ' ||  applicationToUser_message.ORDERID ||  ', OTP: '|| applicationToUser_message.OTP);  
    DBMS_OUTPUT.PUT_LINE (' ');

-- 4: APPLICATION SHARES DELIVERY DETAILS TO DELIVERER
    applicationToDeliverer_message  := enqueueDequeueAQ('aq_appDelivererSubscriber', 'aq_ApplicationQueue', Message_typ(applicationToUser_message.ORDERID, applicationToUser_message.USERNAME, 0, applicationToUser_message.DELIVERYSTATUS, applicationToUser_message.DELIVERYLOCATION));
    DBMS_OUTPUT.PUT_LINE ('APPLICATION TO DELIVERER MESSAGE :  ' || 'ORDERID: ' ||  applicationToDeliverer_message.ORDERID || ', OTP: ' || applicationToDeliverer_message.OTP);  
    DBMS_OUTPUT.PUT_LINE (' ');

-- 5: User shares OTP to DELIVERER
    userToDeliverer_message  := enqueueDequeueAQ('aq_userDelivererSubscriber', 'aq_UserQueue', Message_typ(applicationToUser_message.ORDERID, applicationToUser_message.USERNAME, applicationToUser_message.OTP, applicationToUser_message.DELIVERYSTATUS, applicationToUser_message.DELIVERYLOCATION));
    DBMS_OUTPUT.PUT_LINE ('User TO DELIVERER MESSAGE        :  ' || 'ORDERID: ' ||  userToDeliverer_message.ORDERID || ', OTP: ' || userToDeliverer_message.OTP);  
    DBMS_OUTPUT.PUT_LINE (' ');

-- 6: DELIVERER TO APPLICATION FOR OTP VERIFICATION
    delivererToApplication_message  := enqueueDequeueAQ('aq_delivererAppSubscriber', 'aq_DelivererQueue', Message_typ(userToDeliverer_message.ORDERID, userToDeliverer_message.USERNAME, userToDeliverer_message.OTP, userToDeliverer_message.DELIVERYSTATUS, userToDeliverer_message.DELIVERYLOCATION));
    DBMS_OUTPUT.PUT_LINE ('DELIVERER TO APPLICATION MESSAGE :  ' || 'ORDERID: ' ||  delivererToApplication_message.ORDERID || ', OTP: ' || delivererToApplication_message.OTP);  
    DBMS_OUTPUT.PUT_LINE (' ');

-- 7: APPLICATION VERIFIES OTP WITH USER RECORD AND UPDATE DELIVERY STATUS
    SELECT OTP INTO appOTP FROM USERDETAILS WHERE ORDERID=delivererToApplication_message.ORDERID and DELIVERYSTATUS<>'DELIVERED';

    IF appOTP= delivererToApplication_message.OTP THEN
        UPDATE USERDETAILS SET DELIVERYSTATUS = 'DELIVERED' WHERE ORDERID=delivererToApplication_message.ORDERID;
            DBMS_OUTPUT.PUT_LINE (' ');

        DBMS_OUTPUT.PUT_LINE ('------------------------------');
        DBMS_OUTPUT.PUT_LINE ('OTP VERIFICATION SUCCESS...!!!');
        DBMS_OUTPUT.PUT_LINE ('------------------------------');
            DBMS_OUTPUT.PUT_LINE (' ');

    ELSE 
        UPDATE USERDETAILS SET DELIVERYSTATUS = 'FAILED'    WHERE ORDERID=delivererToApplication_message.ORDERID;
            DBMS_OUTPUT.PUT_LINE (' ');

        DBMS_OUTPUT.PUT_LINE ('-----------------------------');
        DBMS_OUTPUT.PUT_LINE ('OTP VERIFICATION FAILED...!!!');
        DBMS_OUTPUT.PUT_LINE ('-----------------------------');
            DBMS_OUTPUT.PUT_LINE (' ');

    END IF;
    SELECT DELIVERYSTATUS INTO status FROM USERDETAILS      WHERE ORDERID=delivererToApplication_message.ORDERID;
    COMMIT;

-- 8: APPLICATION UPDATE DELIVERER TO DELIVER ORDER
    applicationToDeliverer_message  := enqueueDequeueAQ('aq_appDelivererSubscriber', 'aq_ApplicationQueue', Message_typ(delivererToApplication_message.ORDERID, delivererToApplication_message.USERNAME, delivererToApplication_message.OTP, status, delivererToApplication_message.DELIVERYLOCATION));
    DBMS_OUTPUT.PUT_LINE ('UPDATE DELIVERER MESSAGE         :  ' || 'ORDERID: ' ||  applicationToDeliverer_message.ORDERID || ', DELIVERYSTATUS: ' || applicationToDeliverer_message.DELIVERYSTATUS);  
    DBMS_OUTPUT.PUT_LINE (' ');

-- 9: APPLICATION UPDATE USER FOR DELIVERED ORDER
    applicationToUser_message  := enqueueDequeueAQ('aq_appUserSubscriber', 'aq_ApplicationQueue', Message_typ(delivererToApplication_message.ORDERID, delivererToApplication_message.USERNAME, otp, status, delivererToApplication_message.DELIVERYLOCATION));
    DBMS_OUTPUT.PUT_LINE ('UPDATE USER MESSAGE-             :  ' || 'ORDERID: ' ||  applicationToUser_message.ORDERID || ', DELIVERYSTATUS: ' || applicationToUser_message.DELIVERYSTATUS);  
    DBMS_OUTPUT.PUT_LINE (' ');
END;
/
EXIT;


