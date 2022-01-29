set echo on
set serveroutput on size 20000

declare
  dequeue_options    DBMS_AQ.dequeue_options_t;
  message_properties DBMS_AQ.message_properties_t;
  message_id RAW(2000);
  my_message SYS.AQ$_JMS_TEXT_MESSAGE;
  msg_text varchar2(32767);
begin

    DBMS_OUTPUT.ENABLE (20000);

    -- Dequeue Options
    dequeue_options.dequeue_mode  := DBMS_AQ.REMOVE;
    dequeue_options.wait          := DBMS_AQ.NO_WAIT;
    dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;
    dequeue_options.consumer_name := 'LAB8022_SUBSCRIBER_2';


  DBMS_AQ.DEQUEUE(
    queue_name => 'LAB8022_TOPIC_2',
    dequeue_options => dequeue_options,
    message_properties => message_properties,
    payload => my_message,
    msgid => message_id);
    commit;
    my_message.get_text(msg_text);
    DBMS_OUTPUT.put_line('JMS message: ' || msg_text);
end;
/