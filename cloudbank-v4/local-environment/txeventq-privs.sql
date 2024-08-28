alter session set container=freepdb1;
grant execute on dbms_aq to system with grant option;
grant execute on dbms_aqadm to system with grant option;
grant execute on dbms_aqin to system with grant option;
grant execute on dbms_aqjms TO system with grant option;
grant execute on dbms_aqjms_internal to system with grant option;