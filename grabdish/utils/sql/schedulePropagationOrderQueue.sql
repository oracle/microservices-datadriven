select systimestamp from dual@ORDERTOINVENTORYLINK;

begin
  dbms_aqadm.schedule_propagation(queue_name        => 'ORDERSQ',
                                  destination_queue => 'INVENTORYUSER.ORDERSQ',
                                  destination       => 'ORDERTOINVENTORYLINK',
                                  latency           => 0 );
end ;
/

