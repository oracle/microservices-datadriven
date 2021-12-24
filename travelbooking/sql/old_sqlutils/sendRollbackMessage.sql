CREATE OR REPLACE PROCEDURE sendRollbackMessage(p_sagaId IN VARCHAR2, status OUT VARCHAR2)
IS
   enqueue_options     DBMS_AQ.enqueue_options_t;
   message_properties  DBMS_AQ.message_properties_t;
   message_handle      RAW(16);
   message             SYS.AQ$_JMS_TEXT_MESSAGE;

BEGIN

  message := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
  -- message.text_vc := p_participantInfo;
--  travelagency_json := new JSON_OBJECT_T;
--  travelagency_json.put('travelagencyid', po_travelagency);
--  travelagency_json.put('itemid', po_travelagency);
--  travelagency_json.put('deliveryLocation', po_travelagency);
--  message.set_text(travelagency_json.to_string());
  message.set_text('rollbacksaga');
   message.set_string_property('sagaid', p_sagaId);
  -- message.set_int_property('travelagencyid', p_travelagencyid);
--  INSERT INTO travelagencys_table VALUES (UTL_RAW.convert(UTL_RAW.cast_to_raw(p_travelagencyInfo), 'AL32UTF8','WE8MSWIN1252'));
--    message := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
  DBMS_AQ.ENQUEUE(queue_name => 'ORDERQUEUE',
           enqueue_options    => enqueue_options,
           message_properties => message_properties,
           payload            => message,
           msgid              => message_handle);
  commit;
  status := 'saga rolledback';
END;
/


var travelagencyStatus varchar2;
exec sendRollbackMessage('testrollback', :travelagencyStatus);
