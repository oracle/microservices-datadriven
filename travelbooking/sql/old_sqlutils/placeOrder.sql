
CREATE TABLE travelagencys_table
  (po_travelagency VARCHAR2 (23767)
   CONSTRAINT ensure_json CHECK (po_travelagency IS JSON));

CREATE OR REPLACE PROCEDURE placeOrder(p_travelagencyInfo IN VARCHAR2, travelagencyStatus OUT VARCHAR2)
IS
   enqueue_options     DBMS_AQ.enqueue_options_t;
   message_properties  DBMS_AQ.message_properties_t;
   message_handle      RAW(16);
   message             SYS.AQ$_JMS_TEXT_MESSAGE;

BEGIN

  message := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
  -- message.text_vc := p_participantInfo;
  travelagency_json := new JSON_OBJECT_T;
--  travelagency_json.put('travelagencyid', po_travelagency);
--  travelagency_json.put('itemid', po_travelagency);
--  travelagency_json.put('deliveryLocation', po_travelagency);
--  message.set_text(travelagency_json.to_string());
  message.set_text(p_travelagencyInfo);
  -- message.set_string_property('sagaid', p_sagaid);
  -- message.set_int_property('travelagencyid', p_travelagencyid);
--  INSERT INTO travelagencys_table VALUES (UTL_RAW.convert(UTL_RAW.cast_to_raw(p_travelagencyInfo), 'AL32UTF8','WE8MSWIN1252'));
    message := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
  DBMS_AQ.ENQUEUE(queue_name => 'ORDERQUEUE',
           enqueue_options    => enqueue_options,
           message_properties => message_properties,
           payload            => message,
           msgid              => message_handle);
  commit;
  travelagencyStatus := 'pending';
END;
/
