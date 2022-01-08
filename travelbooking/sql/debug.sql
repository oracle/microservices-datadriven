select * from saga$_travelagency_out_qt;
select MSGID, ENQ_TIME, RETRY_COUNT, SENDER_NAME, USER_DATA, USER_PROP from saga$_travelagency_out_qt;
select * from saga$_travelagency_in_qt;

4select count (*) from TESTQUEUETABLE@participantadminlink  where q_name = 'TESTQUEUE';
select * from ALL_QUEUES;
select * from aq$saga$_carjava_in_qt
select * from saga$_carjava_out_qt;
select * from aq$saga$_carjava_out_qt;

select id, initiator, coordinator, owner, begin_time, status from saga$ order by begin_time asc;
