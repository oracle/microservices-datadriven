-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

set echo on
set serveroutput on size 20000
set serverout on verify off

declare
  txeventq_topic      varchar2(30) := '&1' ;
  txeventq_subscriber varchar2(30) := '&2' ;

  dequeue_options    DBMS_AQ.dequeue_options_t;
  message_properties DBMS_AQ.message_properties_t;
  message_id         RAW(2000);
  my_message         SYS.AQ$_JMS_TEXT_MESSAGE;
  msg_text           varchar2(32767);
begin
    DBMS_OUTPUT.ENABLE (20000);

    if txeventq_topic is not null and txeventq_subscriber is not null
    then
        -- Dequeue Options
        dequeue_options.dequeue_mode  := DBMS_AQ.REMOVE;
        dequeue_options.wait          := DBMS_AQ.NO_WAIT;
        dequeue_options.navigation    := DBMS_AQ.FIRST_MESSAGE;
        dequeue_options.wait          := 1;
        dequeue_options.consumer_name := txeventq_subscriber;

      DBMS_AQ.DEQUEUE(
        queue_name => txeventq_topic,
        dequeue_options => dequeue_options,
        message_properties => message_properties,
        payload => my_message,
        msgid => message_id);
        commit;
        my_message.get_text(msg_text);
        DBMS_OUTPUT.put_line('TxEventQ message: ' || msg_text);
    else
        DBMS_OUTPUT.put_line('ERR : at least one of the variables is null !');
    end if;
end;
/