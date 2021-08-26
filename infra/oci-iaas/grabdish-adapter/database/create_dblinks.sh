while ! state_done ORDER_PROPAGATION; do
  U=$ORDER_USER
  SVC=$ORDER_DB_SVC
  TU=$INVENTORY_USER
  TSVC=$INVENTORY_DB_SVC
  LINK=$ORDER_LINK
  Q=$ORDER_QUEUE
  sqlplus /nolog <<!
WHENEVER SQLERROR EXIT 1
connect $U/"$DB_PASSWORD"@$SVC

create database link $LINK connect to $TU  identified by $DB_PASSWORD using $TSVC;

!
  state_set_done ORDER_PROPAGATION
done
