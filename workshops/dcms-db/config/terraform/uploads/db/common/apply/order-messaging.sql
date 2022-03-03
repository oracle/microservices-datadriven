-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- order_messaging package
create or replace package order_messaging
  authid current_user
as
  procedure enqueue_order_message (in_order in json_object_t);
end order_messaging;
/
show errors

create or replace package body order_messaging
as
  -- Private constants
  order_queue_name      constant varchar2(100) := '$AQ_USER.$ORDER_QUEUE';

  -- enqueue order message
  procedure enqueue_order_message(in_order in json_object_t)
  is
     enqueue_options     dbms_aq.enqueue_options_t;
     message_properties  dbms_aq.message_properties_t;
     message_handle      raw(16);
     message             sys.aq\$_jms_text_message;
  begin
    message := sys.aq\$_jms_text_message.construct;
    message.set_text(in_order.to_string);

    dbms_aq.enqueue(queue_name => order_queue_name,
      enqueue_options    => enqueue_options,
      message_properties => message_properties,
      payload            => message,
      msgid              => message_handle);
  end enqueue_order_message;

end order_messaging;
/
show errors
