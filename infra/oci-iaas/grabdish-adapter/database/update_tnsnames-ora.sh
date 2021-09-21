# shellcheck disable=SC1113
#/usr/bin

CWD=$(dirname "$0")
TARGET_DIR=${CWD}/TNS_ADMIN


#sudo mkdir -p $ TARGET_DIR
#sudo chown -R opc:opc $ TARGET_DIR
#sudo chmod +rwx  $ TARGET_DIR

cp $CWD/tnsnames.ora.example ${TARGET_DIR}/tnsnames.ora
sed -i "s|"%DB_HOSTNAME%"|"grabdish-database1.microservices.onpremise.oraclevcn.com"|g" ${TARGET_DIR}/tnsnames.ora

cp $CWD/listener.ora.example ${TARGET_DIR}/listener.ora
sed -i "s|"%DB_HOSTNAME%"|"grabdish-database1.microservices.onpremise.oraclevcn.com"|g" ${TARGET_DIR}/listener.ora

cp $CWD/sqlnet.ora.example ${TARGET_DIR}/sqlnet.ora
sed -i "s|"%DB_HOSTNAME%"|"grabdish-database1.microservices.onpremise.oraclevcn.com"|g" ${TARGET_DIR}/sqlnet.ora
