export TNS_ADMIN=./wallet
state_get ORDER_DB_NAME
sqlplus orderuser@gdpaulob2o_tp
select systimestamp from dual@ORDERTOINVENTORYLINK;

select SCHEDULE_DISABLED , SCHEMA, QNAME, DESTINATION, FAILURES, LAST_ERROR_DATE, TOTAL_NUMBER,NEXT_RUN_DATE, NEXT_RUN_TIME  from DBA_QUEUE_SCHEDULES;

select count(*) from AQ$orderqueuetable where queue = 'orderqueue';
select count(*) from AQ$inventoryqueuetable where queue = 'inventoryqueue’;
select count(*) from AQ$orderqueuetable@ORDERTOINVENTORYLINK where queue = 'orderqueue';
select count(*) from AQ$inventoryqueuetable@ORDERTOINVENTORYLINK where queue = 'inventoryqueue’;

select * from dba_jobs_running;
select * from DBA_QUEUE_TABLES where QUEUE_TABLE = 'AQ_PROP_TABLE’;

EXECUTE DBMS_AQADM.SCHEDULE_PROPAGATION ( 'orderqueue', 'ORDERTOINVENTORYLINK', sysdate, NULL,   NULL,  60, NULL);
EXECUTE DBMS_AQADM.SCHEDULE_PROPAGATION ( 'inventoryqueue', 'INVENTORYTOORDERLINK', sysdate, NULL,   NULL,  60, NULL);

EXECUTE DBMS_AQADM.ENABLE_PROPAGATION_SCHEDULE ( 'orderuser.orderqueue', 'ORDERTOINVENTORYLINK', 'inventoryuser.orderqueue');
EXECUTE DBMS_AQADM.ENABLE_PROPAGATION_SCHEDULE ( 'inventoryuser.inventoryqueue', 'INVENTORYTOORDERLINK', 'orderuser.inventoryqueue');


select qname, destination, schedule_disabled, last_run_date, next_run_date, failures, last_error_date, last_error_msg from dba_queue_schedules where qname = 'inventoryuser.inventoryqueue';


select qname, destination, schedule_disabled, last_run_date, next_run_date, failures, last_error_date, last_error_msg from dba_queue_schedules where qname = 'orderuser.orderqueue';

select propagation_name, STATUS, ERROR_MESSAGE, ERROR_DATE from all_propagation where SOURCE_QUEUE_OWNER='ORDERUSER';


select propagation_name, STATUS, ERROR_MESSAGE, ERROR_DATE from all_propagation where SOURCE_QUEUE_OWNER='INVENTORYUSER';
