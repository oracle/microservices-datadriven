const oracledb = require('oracledb');

async function run() {

  let connection;

  try {
    const config = { connectString: process.env.DB_ALIAS, externalAuth: true };
    const connection = await oracledb.getConnection(config); 

    cleanUp(connection,"NODE_AQ_ADT_TABLE", "NODE_AQ_ADT" );
    cleanUp(connection,"NODE_AQ_RAW_TABLE", "NODE_AQ_RAW" );
    cleanUp(connection,"NODE_AQ_JMS_TABLE", "NODE_AQ_JMS" );

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
    await conn.execute(`
        BEGIN
            DBMS_AQADM.STOP_QUEUE( QUEUE_NAME =>  '`.concat(queueName).concat(`');
        END;`)
    );
 
    await conn.execute(`
        BEGIN
            DBMS_AQADM.DROP_QUEUE( QUEUE_NAME  =>  '`.concat(queueName).concat(`');
        END;`)
    );

    await conn.execute(`
        BEGIN
            DBMS_AQADM.DROP_QUEUE_TABLE( QUEUE_TABLE => '`.concat(queueTable).concat(`');
        END;`)
    );
}