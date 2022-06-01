const oracledb = require('oracledb');

async function run() {

  let connection;

  try {
    const config = { connectString: process.env.DB_ALIAS, externalAuth: true };
    const connection = await oracledb.getConnection(config); 

    await connection.execute('CREATE OR REPLACE TYPE NODE_TEQ_MESSAGE_TYPE AS OBJECT (NAME        VARCHAR2(10),ADDRESS     VARCHAR2(50))'); 

    createQueue(connection, "NODE_TEQ_ADT" , "NODE_TEQ_MESSAGE_TYPE" ,"SUBSCRIBER_NODE_TEQ_ADT");
    createQueue(connection, "NODE_TEQ_RAW" , "RAW" ,"SUBSCRIBER_NODE_TEQ_RAW");
    createQueue(connection, "NODE_TEQ_JMS" , "JMS" ,"SUBSCRIBER_NODE_TEQ_JMS");
    createQueue(connection, "NODE_TEQ_JSON", "JSON","SUBSCRIBER_NODE_TEQ_JSON");


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

async function createQueue(conn, queueName, payload, subscriberName) {
    await conn.execute(`
        BEGIN
            DBMS_AQADM.CREATE_TRANSACTIONAL_EVENT_QUEUE(
                queue_name         =>'`.concat(queueName).concat(`',
                storage_clause     =>null, 
                multiple_consumers =>true, 
                max_retries        =>10,
                comment            =>'Node.js Samples for TEQ', 
                queue_payload_type =>'`).concat(payload).concat(`', 
                queue_properties   =>null, 
                replication_mode   =>null
            );
        END;`)
    );
    
    await conn.execute(`
        BEGIN
            DBMS_AQADM.START_QUEUE(
                queue_name=>'`.concat(queueName).concat(`', 
                enqueue =>TRUE, 
                dequeue=> True
            ); 
        END;`)
    );
    
    await conn.execute(`
        DECLARE
            subscriber sys.aq$_agent;
        BEGIN
            DBMS_AQADM.add_subscriber(
                queue_name =>'`.concat(queueName).concat(`', 
                subscriber => sys.aq$_agent('`).concat(subscriberName).concat(`', null ,0)
            ); 
        END;`)
    );

}