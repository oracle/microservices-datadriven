const oracledb = require('oracledb');

async function run() {

  let connection;

  try {
    const config = { connectString: process.env.DB_ALIAS, externalAuth: true };
    const connection = await oracledb.getConnection(config); 

    await connection.execute('CREATE OR REPLACE TYPE NODE_AQ_MESSAGE_TYPE AS OBJECT (NAME        VARCHAR2(10),ADDRESS     VARCHAR2(50))'); 

    createQueue(connection,"NODE_AQ_ADT_TABLE", "NODE_AQ_ADT" , "NODE_AQ_MESSAGE_TYPE");
    createQueue(connection,"NODE_AQ_RAW_TABLE", "NODE_AQ_RAW" , "RAW");
    createQueue(connection,"NODE_AQ_JMS_TABLE", "NODE_AQ_JMS" , "SYS.AQ$_JMS_TEXT_MESSAGE");

    const result = await connection.execute("select name, queue_table, dequeue_enabled,enqueue_enabled, sharded, queue_category, recipients from all_queues where OWNER='JAVAUSER' ");
    console.dir(result.rows);

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

async function createQueue(conn, queueTable, queueName, payload) {
  await conn.execute(`
      BEGIN
        DBMS_AQADM.CREATE_QUEUE_TABLE(
          QUEUE_TABLE        =>  '`.concat(queueTable).concat(`',
          QUEUE_PAYLOAD_TYPE =>  '`).concat(payload).concat(`');
      END;`)
  );
        
  await conn.execute(`
      BEGIN
        DBMS_AQADM.CREATE_QUEUE(
          QUEUE_NAME         =>  '`.concat(queueName).concat(`',
          QUEUE_TABLE        =>  '`).concat(queueTable).concat(`');
      END;`));

  await conn.execute(`
      BEGIN
        DBMS_AQADM.START_QUEUE(
          QUEUE_NAME         =>  '`.concat(queueName).concat(`');
      END;`)
  );
}