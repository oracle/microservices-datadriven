cd $ORACLEAQ_HOME;

#TERMINATE JAVA
killall -9 java;

#DELETE ATP
oci db autonomous-database delete --autonomous-database-id ${DB_ID} --force --wait-for-state SUCCEEDED;

#DELETE COMPARTMENT
oci iam compartment delete -c ${COMPARTMENT_OCID} --force --wait-for-state SUCCEEDED