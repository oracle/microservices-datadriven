const oracledb = require("oracledb");

async function run() {
  let connection;

  try {
    const config = { connectString: process.env.DB_ALIAS, externalAuth: true };
    const connection = await oracledb.getConnection(config);

    cleanUp(connection, "NODE_TxEventQ_ADT");
    cleanUp(connection, "NODE_TxEventQ_RAW");
    cleanUp(connection, "NODE_TxEventQ_JMS");
    cleanUp(connection, "NODE_TxEventQ_JSON");
  } catch (err) {
    console.error(err);
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error(err);
      }
    }
  }
}
run();

async function cleanUp(conn, queueTable, queueName) {
  await conn.execute(
    `
        BEGIN
            DBMS_AQADM.STOP_QUEUE( QUEUE_NAME =>  '`.concat(queueName)
      .concat(`');
        END;`)
  );

  await conn.execute(
    `
        BEGIN
            DBMS_AQADM.DROP_TRANSACTIONAL_QUEUE( 
                QUEUE_NAME  =>  '`.concat(queueName).concat(`',
                FORCE       => TRUE
            );
        END;`)
  );
}
