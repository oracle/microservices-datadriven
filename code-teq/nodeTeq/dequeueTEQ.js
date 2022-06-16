//
//  This sample demonstrates how to dequeue a message from a TEQ using JavaScript/Node
//

//  There are various payload types supported, including user-defined object, raw, JMS and JSON.
//  This sample uses the RAW payload type.

//  Execute permission on dbms_aq is required.
//  The node module 'oracledb' must be installed, e.g. with npm

const oracledb = require('oracledb');

// declare an async function to do the work, since most of the APIs in the 
// oracledb node library are async
async function run() {
  let connection;

  try {
    // get a connection to the database
    oracledb.initOracleClient({});
    connection = await oracledb.getConnection({
        user: 'pdbadmin',
        password: process.env.DB_PASSWORD,
        connectString: 'localhost:1521/pdb1'
    })

    // dequeue a message
    const rawQueue = await connection.getQueue("my_raw_teq");
    rawQueue.deqOptions.consumerName = "my_subscriber";
    rawQueue.deqOptions.wait=oracledb.AQ_DEQ_NO_WAIT;
    const rawDeq = await rawQueue.deqOne();
    await connection.commit();
    
    // RAW data is returned as a buffer, so we need to convert to a string
    // before displaying the data
    const buffer = Buffer.from(rawDeq.payload)
    console.log(buffer.toString());

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

// entry point
run();