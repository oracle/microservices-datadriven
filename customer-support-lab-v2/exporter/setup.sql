-- Called by setup.sh as SYS in the primary CDB root. No application data changes.
define app_username = '&1'
define metrics_password = '&2'
declare
    present number;
begin
    select count(*) into present from dba_users where username = 'C##LAB_METRICS';
    if present = 0 then
        execute immediate 'create user C##LAB_METRICS identified by "&&metrics_password" container=all';
    else
        execute immediate 'alter user C##LAB_METRICS identified by "&&metrics_password" account unlock container=all';
    end if;
end;
/
grant create session to C##LAB_METRICS container=all;
grant select on sys.gv_$session to C##LAB_METRICS container=all;
grant select on sys.gv_$resource_limit to C##LAB_METRICS container=all;
grant select on sys.gv_$sysstat to C##LAB_METRICS container=all;
grant select on sys.gv_$system_wait_class to C##LAB_METRICS container=all;
grant select on sys.gv_$sysmetric to C##LAB_METRICS container=all;
grant select on sys.gv_$sga to C##LAB_METRICS container=all;
grant select on sys.gv_$pgastat to C##LAB_METRICS container=all;
grant select on sys.v_$recovery_file_dest to C##LAB_METRICS container=all;
grant select on sys.v_$true_cache_stat to C##LAB_METRICS container=all;
grant select on sys.dba_tablespace_usage_metrics to C##LAB_METRICS container=all;
grant select on sys.dba_tablespaces to C##LAB_METRICS container=all;
alter user C##LAB_METRICS set container_data=all container=current;

alter session set container=FREEPDB1;
grant select on &&app_username..support_ticket to C##LAB_METRICS;
grant select on &&app_username..failed_ticket_event to C##LAB_METRICS;
grant select on &&app_username..ticket_approval_history to C##LAB_METRICS;
grant select on &&app_username..ticket_assistance to C##LAB_METRICS;
grant select on &&app_username..support_policy to C##LAB_METRICS;
-- Stable names keep custom SQL independent of the configurable application schema.
create or replace view C##LAB_METRICS.lab_ticket_state as
    select id, workflow_status from &&app_username..support_ticket;
create or replace view C##LAB_METRICS.lab_failure_state as
    select event_id, status from &&app_username..failed_ticket_event;
create or replace view C##LAB_METRICS.lab_review_state as
    select action_id, decision from &&app_username..ticket_approval_history;
create or replace view C##LAB_METRICS.lab_policy_state as
    select case when embedding is null then 0 else 1 end indexed
    from &&app_username..support_policy;
prompt Read-only lab metrics user is ready.
