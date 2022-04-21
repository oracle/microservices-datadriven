const oracledb = require('oracledb');

async function run() {

  let connection;

  try {
    const config = { connectString: process.env.DB_ALIAS, externalAuth: true };
    const connection = await oracledb.getConnection(config); 

    createQueue(connection,"NODE_TEQ_ADT" );
    createQueue(connection,"NODE_TEQ_RAW" );
    createQueue(connection,"NODE_TEQ_JMS" );

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

 DBMS_AQADM.STOP_QUEUE ( queue_name => 'objType_TEQ'); 
 DBMS_AQADM.drop_transactional_event_queue(queue_name =>'objType_TEQ',force=> TRUE);

    await conn.execute(`
        BEGIN
            DBMS_AQADM.STOP_QUEUE( QUEUE_NAME =>  '`.concat(queueName).concat(`');
        END;`)
    );
 
    await conn.execute(`
        BEGIN
            DBMS_AQADM.DROP_TRANSACTIONAL_QUEUE( 
                QUEUE_NAME  =>  '`.concat(queueName).concat(`',
                FORCE       => TRUE
            );
        END;`)
    );

}