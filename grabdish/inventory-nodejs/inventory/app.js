// Copyright (c) 2021 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
"use strict";

const oracledb = require('oracledb');
const express = require('express');
const identity = require("oci-identity");
const common = require('oci-common');
const secrets = require('oci-secrets');

const {param, validationResult} = require('express-validator');
const morgan = require('morgan'); 
const drainDelay = 10;
const fs = require('fs');
const readyFile = '/tmp/njsInvReady';
let statsStream;
let server = {};
let pwDecoded = "";

async function getSecret() {
  const provider = await new common.InstancePrincipalsAuthenticationDetailsProviderBuilder().build();
  try {
      const secretConfig = {
       secretInfo: {
         regionid: process.env.OCI_REGION,
         vaultsecretocid: process.env.VAULT_SECRET_OCID,
         k8ssecretdbpassword: process.env.dbpassword
       }
      };
      if  (secretConfig.secretInfo.vaultsecretocid == "") {
        pwDecoded = process.env.dbpassword;
      } else {
        console.log("regionid: ", secretConfig.secretInfo.regionid);
        console.log("vaultsecretocid: ", secretConfig.secretInfo.vaultsecretocid);
        const client =  new secrets.SecretsClient({
            authenticationDetailsProvider: provider
        });
        const getSecretBundleRequest = {
                secretId: secretConfig.secretInfo.vaultsecretocid
            };
        const getSecretBundleResponse = await client.getSecretBundle(getSecretBundleRequest);
        const pw = getSecretBundleResponse.secretBundle.secretBundleContent.content;
        let buff = new Buffer(pw, 'base64');
        pwDecoded = buff.toString('ascii');
      }
  } catch (e) {
    throw Error(`Failed with error: ${e}`);
  }
}

const dbConfig = {
  inventoryPool: {
    user: process.env.DB_USER.trim(),
    password: pwDecoded,
    connectString: process.env.DB_CONNECT_STRING,
    poolMin: Number(process.env.DB_CONNECTION_COUNT) || 10,
    poolMax: Number(process.env.DB_CONNECTION_COUNT) || 10,
    poolIncrement: process.env.DB_POOL_INC || 0  
  }
};

const webConfig = {
  port: process.env.HTTP_PORT || 8081
};

const queueConfig = {
  orderQueue: process.env.AQ_ORDERS_QUEUE_NAME || 'inventoryuser.orderqueue',
  inventoryQueue: process.env.AQ_INVENTORY_QUEUE_NAME || 'inventoryuser.inventoryqueue'
};

const queueOptions = {
  payloadType: "SYS.AQ$_JMS_TEXT_MESSAGE"
};

// Database pool configuration
// Notes:
//   Not adding events here by default so that we don't override the default behavior.
// Depending upon the size of the configured database connect pool value poolMax, 
// determine if need to increase thread pool size for lduv Increase thread pool size by poolMax
// This has to be done initially before any threads are used in async processing.
// TODO - Consider whether to change the calculation to be inclusive of the default 4
//        or whether to consider additive, as in the current calculation. The referenced
//        docs say to ensure changing if pool is > than the default, but if there is other
//        processing to consider increasing, so for now have treated as additive.
// References:
// - libuv documentation here: http://docs.libuv.org/en/v1.x/threadpool.html
// - node-oracledb documentation here: https://oracle.github.io/node-oracledb/doc/api.html#numberofthreads
const defaultUVThreadPoolSize = 4;  
const currUVThreadPoolSize = process.env.UV_THREADPOOL_SIZE || defaultUVThreadPoolSize;
if (currUVThreadPoolSize < defaultUVThreadPoolSize + dbConfig.inventoryPool.poolMax) {

  console.log('Overriding UV_THREADPOOL_SIZE because current UV Thread Pool Size [%d] < default UV Thread Pool Size [%d] + Database Pool Max [%d]', currUVThreadPoolSize, defaultUVThreadPoolSize, dbConfig.inventoryPool.poolMax);
  process.env.UV_THREADPOOL_SIZE = dbConfig.inventoryPool.poolMax + defaultUVThreadPoolSize;
} else {
  console.log('Not setting UV_THREADPOOL_SIZE because current UV Thread Pool Size [%d] >= default UV Thread Pool Size [%d] + Database Pool Max [%d]', currUVThreadPoolSize, defaultUVThreadPoolSize, dbConfig.inventoryPool.poolMax);
} 

// Determine whether to enable FAN events at the module level.
// Events are disabled by default. In node-oracledb 4.0.0 and 4.0.1 they were enabled by default
// However, as of node-oracledb 4.2.0, they are still disabled by default (events=false)
switch (process.env.DB_M_FAN_EVENTS) {
  case 'false':
    console.log('Setting oracledb.events to false...');
    oracledb.events = false;
    break;
  case 'true':
    console.log('Setting oracledb.events to true...');
    oracledb.events = true;
    break;
  default:
    console.log('Keeping default value for oracledb.events...');
}
console.log('oracledb.events = [%s]', oracledb.events);

// Determine whether to override the value of queueTimeout at the Connection Pool level. By default, will be set to 60000 ms
if (process.env.DB_CP_QUEUE_TIMEOUT) {
  console.log('Setting dbConfig.inventoryPool.queueTimeout to environment variable value [%s]...', process.env.DB_CP_QUEUE_TIMEOUT);
  dbConfig.inventoryPool.queueTimeout = Number(process.env.DB_CP_QUEUE_TIMEOUT);
} else {
  console.log('Keeping default value for Connection Pool Queue Timeout');
}

//console.log('dbConfig.inventoryPool = [%s]', JSON.stringify(dbConfig.inventoryPool));

const app = express();
app.use(morgan('combined'));
app.use(express.json());

async function logStats(name, start, end, errorCount=0) {
  const currentDateTime = new Date().toISOString();
  //console.log(`STAT|${currentDateTime}|${name}|${end - start}`);
  statsStream.write(`${currentDateTime}|${name}|${end - start}|${errorCount}\n`);
}

async function processOrders() {
  while (true) {
    try {
      await processOrder();
    } catch (err) {
      // console.log(err);
      if (err.errorNum) {
        console.log(`Oracle error ${err.errorNum}, continuing processing...`);
        // TODO - Test for logic if database is down, don't retry, wait a certain amount of time, then retry
        //        with new connection.
        // TODO - Become non-ready
      } else {
        console.log(`Non-Oracle error. No longer processing order updates.`);
        // TODO - Set no longer healthy here
        // TODO - Consider whether to explictly close here by either close() or throwing the error
        //        For now simply breaking the loop here to ensure we don't block SIGINT or another
        //        explict close.
        break;
      }
    }
  }
}

async function processOrder() {
  let connection;
  let bindVariables = {};
  let options = {};
  let action;
  let location;
  let opName = 'Inventory:ordQConsumerInit';
  let opStart = process.hrtime.bigint();

  try {
    oracledb.autoCommit = false;
    connection = await oracledb.getConnection();
    const orderQueue = await connection.getQueue(queueConfig.orderQueue, queueOptions);
    orderQueue.deqOptions.navigation = oracledb.AQ_DEQ_NAV_FIRST_MSG;  // Required for TEQ
    orderQueue.deqOptions.consumerName = 'inventory_service';
    logStats(opName, opStart, process.hrtime.bigint());
    const orderMsg = await orderQueue.deqOne();
    opName = 'Inventory:ordQConsumer';
    opStart = process.hrtime.bigint();
    const orderMsgContent = JSON.parse(orderMsg.payload.TEXT_VC);
    const updateSQL = 
`update inventory
   set inventorycount = inventorycount - 1
 where 1=1
   and inventoryid = :inventoryid
   and inventorycount > 0
 returning inventorylocation
      into :inventorylocation`;
    
    if ((orderMsgContent) && (orderMsgContent.itemid) && (orderMsgContent.orderid)) {
      bindVariables.inventoryid = orderMsgContent.itemid
    }
      
    bindVariables.inventorylocation = {
      dir: oracledb.BIND_OUT,
      type: oracledb.STRING
    };

    options.outFormat = oracledb.OUT_FORMAT_OBJECT;

    //console.log(`bindVariables = ${JSON.stringify(bindVariables)}`);
   
    const queryResult = await connection.execute(updateSQL, bindVariables, options);

    if (queryResult.rowsAffected && queryResult.rowsAffected === 1) {
      location = queryResult.outBinds.inventorylocation[0];
    } else {
      location = "inventorydoesnotexist";
    }

    const inventoryQueue = await connection.getQueue(queueConfig.inventoryQueue, queueOptions);
 
    const inventoryMsgText = JSON.stringify({
      orderid: orderMsgContent.orderid,
      itemid: orderMsgContent.itemid,
      inventorylocation: location,
      suggestiveSale: "beer"
    });
    const inventoryMsgContent = new inventoryQueue.payloadTypeClass({
      TEXT_VC: inventoryMsgText,
      TEXT_LEN: inventoryMsgText.length
    });

    //console.log(`Enqueuing message ${JSON.stringify(inventoryMsgContent)} into inventoryQueue ${queueConfig.inventoryQueue}`);
    const inventoryMsg = await inventoryQueue.enqOne({payload: inventoryMsgContent, priority: 2});
    await connection.commit();
    
    logStats(opName, opStart, process.hrtime.bigint());  
    
    console.log(`Processed order ${JSON.stringify(orderMsgContent)} and inventory update ${JSON.stringify(inventoryMsgContent)}`);
  } catch (err) {
    console.log(err);
    logStats(opName, opStart, process.hrtime.bigint(), 1);  
    throw(err);
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.log(err);
      }
    }
  }
}

// TODO - Consider what additional validations can be made
// TODO - Consider what sanitization can/should be made
// TODO - Currently explicitly checking the query parameters. Determine whether to check all via check method (params, body, query). At the moment, only checking and processing query parameters.
// TODO - Currently only supporting querying for a single order via this validation. May want to support seeing all orders for debugging purposes while developing
function getParamValidations() {
  const validations = [
    param('inventoryid', 'inventoryid if provided must not be empty').notEmpty().isLength({max:16})
  ];

  return validations;
}

async function getInventory(req, res, next) {
  let connection;
  let bindVariables = {};
  const sqlStatement = 
`select inventoryid "inventoryid"
   , inventorylocation "inventorylocation"
   , inventorycount "inventorycount"
from inventory
where 1=1
  and inventoryid = :inventoryid`;

  let options = {};
  const opName = 'Inventory:getInventory';
  const opStart = process.hrtime.bigint();
  
  try {
    const errors = validationResult(req);
    
    if (!errors.isEmpty()) {
      logStats(opName, opStart, process.hrtime.bigint(), 1);
      return res.status(422).jsonp(errors.array());
    }

    bindVariables.inventoryid = req.params.inventoryid;

    options.outFormat = oracledb.OUT_FORMAT_OBJECT;

    connection = await oracledb.getConnection();
    
    const queryResult = await connection.execute(sqlStatement, bindVariables, options);

    if (queryResult.rows.length === 1) {
      res.status(200).json(queryResult.rows[0]);
      logStats(opName, opStart, process.hrtime.bigint());
    } else {
      res.sendStatus(404);
      logStats(opName, opStart, process.hrtime.bigint(), 1);
    }
  } catch (err) {
    console.log(err);
    logStats(opName, opStart, process.hrtime.bigint(), 1);
    next(err);
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.log(err);
      }
    }
  }
}

app.get('/inventory/:inventoryid', getParamValidations(), getInventory);

async function initDB() {
 // console.log(`Creating database connection pool with configuration ${JSON.stringify(dbConfig.inventoryPool)}`);
  await getSecret();
  dbConfig.inventoryPool.password = pwDecoded;
//  console.log('dbConfig.inventoryPool.password:' + dbConfig.inventoryPool.password);
  const pool = await oracledb.createPool(dbConfig.inventoryPool);
  console.log('Database connection pool created');
  
  console.log('Initializing order queue processing');
  processOrders(); 
}

async function initWeb() {
  server = app.listen(webConfig.port);

  server.on('listening', () => {
    console.log(`Http server listening on port [${webConfig.port}]`);
    // Set readiness (async, not waiting as we are ready)
    console.log(`Writing ready file ${readyFile}`);
    fs.writeFile(readyFile, 'ready', (err) => {
      if (err) {
        console.error(err.message);
        throw err;
      } else {
        console.log(`Ready file written.`);
      }
    });
  });
}

async function closeDB(delay) {
  // Close the default connection pool with 10 seconds draining
  // TODO - See with volume testing whether this makes a difference given other logic
  console.log(`Closing database connection pool with drain time [${delay}] seconds`);
  await oracledb.getPool().close(delay);
  console.log('Database connection pool closed');
}

async function closeWeb() {
  // TODO - Add drain
  await server.close();
}


async function init() {
  console.log('Initializing application');
  
  try {
    console.log('Opening stats log file for write.');
    statsStream = fs.createWriteStream('stats.log');
  } catch (err) {
    console.error(err);

    process.exit(1);
  }

  try {
    console.log('Initializing database');
    await initDB();
  } catch (err) {
    console.error(err);

    process.exit(1);
  }

  try {
    console.log('Initializing web server');
    await initWeb();
  } catch (err) {
    console.error(err);

    try {
      await closeDB(0);
  
    } catch(err) {
      console.error(err.message);
      
      process.exit(1);
    }

    process.exit(1);
  }

  console.log('Application initialization complete');
}

async function close() {
  console.log('\nTerminating application');
  let errCount = 0;

  // Stop readiness
  console.log(`Attempting to delete ready file ${readyFile}`);
  try {
    fs.unlinkSync(readyFile);
    console.log(`Ready file ${readyFile} deleted.`);

  } catch(err) {
    console.error(err.message);
    
    errCount++;
  }

  try {
    await closeWeb();

  } catch(err) {
    console.error(err.message);
    
    errCount++;
  }

  try {
    await closeDB(drainDelay);

  } catch(err) {
    console.error(err.message);
    
    errCount++;
  }

  if (errCount > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

process
  .once('SIGTERM', close)
  .once('SIGINT', close);


init();




