//
//  This sample demonstrates how to enqueue a message onto a TEQ using JavaScript/Node
//

//  There are various payload types supported, including user-defined object, raw, JMS and JSON.
//  This sample uses the RAW payload type.

//  Execute permission on dbms_aq is required.

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

    // enqueue a message
    console.log("Enqueueing one message with RAW payload");
    const rawQueue = await connection.getQueue("my_raw_teq");
    await rawQueue.enqOne("This is a RAW message");
    await connection.commit();

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