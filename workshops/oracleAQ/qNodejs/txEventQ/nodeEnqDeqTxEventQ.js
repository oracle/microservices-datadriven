const oracledb = require("oracledb");

async function run() {
  let connection;

  try {
    const config = { connectString: process.env.DB_ALIAS, externalAuth: true };
    const connection = await oracledb.getConnection(config);
    /*ADT PAYLOAD*/
    console.log("1)Enqueue one message with ADT payload ");
    const adtQueue = await connection.getQueue("NODE_TxEventQ_ADT", {
      payloadType: "NODE_TxEventQ_MESSAGE_TYPE",
    });
    const message = new adtQueue.payloadTypeClass({
      NAME: "scott",
      ADDRESS: "The Kennel",
    });
    await adtQueue.enqOne((props = { payload: message }));
    /*await adtQueue.enqOne(message);*/
    await connection.commit();
    console.log("Enqueue Done!!!");
    const adtResult = await connection.execute(
      "Select QUEUE, USER_DATA from AQ$NODE_TxEventQ_ADT_TABLE"
    );
    console.dir(adtResult.rows);

    adtQueue.deqOptions.consumerName = "SUBSCRIBER_NODE_TxEventQ_ADT";
    adtQueue.deqOptions.wait = oracledb.AQ_DEQ_NO_WAIT;
    const adtDeq = await adtQueue.deqOne();
    console.dir(adtDeq.payload());
    await connection.commit();
    console.log("Dequeued message with ADT payload : ", adtDeq.payload.NAME);
    console.log("Dequeue Done!!!");
    console.log(
      "-----------------------------------------------------------------"
    );

    /*RAW PAYLOAD*/
    console.log("2)Enqueue one message with RAW payload ");
    const rawQueue = await connection.getQueue("NODE_TxEventQ_RAW");
    await rawQueue.enqOne("This is my RAW message");
    await connection.commit();
    console.log("Enqueue Done!!!");
    const rawResult = await connection.execute(
      "Select QUEUE, USER_DATA from AQ$NODE_TxEventQ_RAW_TABLE"
    );
    console.dir(rawResult.rows);

    rawQueue.deqOptions.consumerName = "SUBSCRIBER_NODE_TxEventQ_RAW";
    rawQueue.deqOptions.wait = oracledb.AQ_DEQ_NO_WAIT;
    const rawDeq = await rawQueue.deqOne();
    await connection.commit();
    console.dir(rawDeq.payload);
    await connection.commit();
    console.log("Dequeued message with ADT payload : ", rawDeq.payload);
    console.log("Dequeue Done!!!");
    console.log(
      "-----------------------------------------------------------------"
    );
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
