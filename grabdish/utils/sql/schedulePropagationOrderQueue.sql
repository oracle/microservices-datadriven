begin
  dbms_aqadm.schedule_propagation(queue_name        => 'ORDERSQ',
                                  destination_queue => 'ORDERUSER.INVENTORYQ',
                                  destination       => 'ORDERTOINVENTORYLINK',
                                  latency           => 0 );
end ;
/

select systimestamp from dual@ORDERTOINVENTORYLINK;
