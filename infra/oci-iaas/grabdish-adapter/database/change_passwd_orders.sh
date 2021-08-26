#/bin/bash

# Fail on error
set -e

ORDER_DB_SVC=orders
INVENTORY_DB_SVC=inventory
ORDER_USER=ORDERUSER
INVENTORY_USER=INVENTORYUSER

SVC=$ORDER_DB_SVC
USER=$ORDER_USER

echo "###########################################################"
echo "Altering User $USER password for PDB $SVC"
echo "###########################################################"
echo ""

# Get DB Password
DB_PASSWORD="$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq --raw-output  '.grabdish_database_password')"

sqlplus sys/"$DB_PASSWORD"@$(hostname):1521/orcl as SYSDBA <<!
set ECHO ON;
alter session set container=$SVC;
alter user $USER IDENTIFIED BY "$DB_PASSWORD";
alter user ADMIN IDENTIFIED BY "$DB_PASSWORD";
/
!

echo ""
echo "###########################################################"
echo "Altered Users ${USER}, ADMIN password for PDB $SVC"
echo "###########################################################"