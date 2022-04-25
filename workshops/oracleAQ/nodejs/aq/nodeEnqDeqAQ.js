const oracledb = require('oracledb');

async function run() {

  let connection;

  try {
    const config = { connectString: process.env.DB_ALIAS, externalAuth: true };
    const connection = await oracledb.getConnection(config); 

    /*ADT PAYLOAD*/
    console.log("1)Enqueue one message with ADT payload ");
    const adtQueue = await connection.getQueue("NODE_AQ_ADT", {payloadType: "NODE_AQ_MESSAGE_TYPE"});
    const message = new adtQueue.payloadTypeClass(
        {
          NAME: "scott",
          ADDRESS: "The Kennel"
        }
    );
    await adtQueue.enqOne(props={payload: message});
   /* await adtQueue.enqOne(message);*/
    await connection.commit();
    console.log("Enqueue Done!!!")AQ$NODE_AQ_ADT_TABLE
    const adtResult = await connection.execute("Select QUEUE, USER_DATA from AQ$NODE_AQ_ADT_TABLE");
    console.dir(adtResult.rows);
    
    const adtMsg = await adtQueue.deqOne();
    await connection.commit();
    console.log("Dequeued message with ADT payload : ",adtMsg.payload.NAME)
    console.log("Dequeue Done!!!") 
    console.log("-----------------------------------------------------------------")

    /*RAW PAYLOAD*/
    console.log("2)Enqueue one message with RAW payload ");
    const queue = await connection.getQueue("NODE_AQ_RAW");
    await queue.enqOne("This is my RAW message");
    await connection.commit();
    console.log("Enqueue Done!!!")
    const rawResult = await connection.execute("Select QUEUE, USER_DATA from AQ$NODE_AQ_RAW_TABLE");
    console.dir(rawResult.rows);

    const rawMsg = await queue.deqOne();
    await connection.commit();
    console.log("Dequeued message with ADT payload : ",rawMsg.payload)
    console.log("Dequeue Done!!!") 
    console.log("-----------------------------------------------------------------")

    /*JMS PAYLOAD*/
    /*const queue = await connection.getQueue("NODE_AQ_JMS");
    await queue.enqOne("This is my JMS message");
    await connection.commit();
    const Result = await connection.execute("Select QUEUE, USER_DATA from AQ$NODE_AQ_JMS_TABLE");
    console.dir(Result.rows);

    const msg = await queue.deqOne();
    await connection.commit();*/
    
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