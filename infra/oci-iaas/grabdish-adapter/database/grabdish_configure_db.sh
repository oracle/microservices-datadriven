sqlplus / as SYSDBA  @create_order_pdb.sql
sqlplus / as SYSDBA  @grant_privilege_orders.sql
sqlplus ORDERUSER/"Welcome123"@orders_tp @create_order_aqs.sql