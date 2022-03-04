-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- order_messaging package
create or replace package inventory_messaging
  authid current_user
as
  procedure enqueue_inventory_message (in_inv_msg in json_object_t);
  function dequeue_order_message(in_wait_option in binary_integer) return json_object_t;
end inventory_messaging;
/
show errors

create or replace package body inventory_messaging
as
  -- Private constants
  order_queue_name       constant varchar2(100) := '$AQ_USER.$ORDER_QUEUE';
  inventory_queue_name   constant varchar2(100) := '$AQ_USER.$INVENTORY_QUEUE';
  inventory_service_name constant varchar2(100) := '$INVENTORY_SERVICE_NAME'; -- Subscriber Name

  -- enqueue order message
  procedure enqueue_inventory_message(in_inv_msg in json_object_t)
  is
    enqueue_options      dbms_aq.enqueue_options_t;
    message_properties   dbms_aq.message_properties_t;
    message_handle       raw(16);
    message              $QUEUE_MESSAGE_TYPE;
  begin
    message := $QUEUE_MESSAGE_TYPE.construct;
    message.set_text(in_inv_msg.to_string);

    dbms_aq.enqueue(queue_name => inventory_queue_name,
      enqueue_options    => enqueue_options,
      message_properties => message_properties,
      payload            => message,
      msgid              => message_handle);
  end enqueue_inventory_message;

  function dequeue_order_message(in_wait_option in binary_integer) return json_object_t
  is
    dequeue_options      dbms_aq.dequeue_options_t;
    message_properties   dbms_aq.message_properties_t;
    message_handle       raw(16);
    message              $QUEUE_MESSAGE_TYPE;
    no_messages          exception;
    pragma               exception_init(no_messages, -25228);
  begin
    case in_wait_option
    when 0 then
      dequeue_options.wait := dbms_aq.no_wait;
    when -1 then
      dequeue_options.wait := dbms_aq.forever;
    else
      dequeue_options.wait := in_wait_option;
    end case;

    dequeue_options.consumer_name := inventory_service_name;
    dequeue_options.navigation    := dbms_aq.first_message;  -- Required for TEQ

    dbms_aq.dequeue(
      queue_name         => order_queue_name,
      dequeue_options    => dequeue_options,
      message_properties => message_properties,
      payload            => message,
      msgid              => message_handle);

    return json_object_t(message.text_vc);

    exception
      when no_messages then
        return null;
      when others then
        raise;
  end dequeue_order_message;

end inventory_messaging;
/
show errors
