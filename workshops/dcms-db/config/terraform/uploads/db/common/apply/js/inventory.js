// Copyright (c) 2021 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

// global constants
const db = require("mle-js-oracledb");
const bindings = require("mle-js-bindings");
const conn = db.defaultConnection();

// addInventory - API
function addInventory(itemid) {
  try {
    conn.execute(
      "update inventory set inventorycount=inventorycount + 1 where inventoryid = :1", 
      [itemid]
    );
    conn.commit;
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// removeInventory - API
function removeInventory(itemid) {
  try {
    conn.execute( 
      "update inventory set inventorycount=inventorycount - 1 where inventoryid = :1", 
      [itemid]
    );
    conn.commit;
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// getInventory - API
function getInventory(itemid) {
  try {
    let result = conn.execute( 
      "select inventorycount into :invcount from inventory where inventoryid = :itemid", 
      {
        invcount: { dir: db.BIND_OUT, type: db.STRING },
        itemid: { val: itemid, dir: db.BIND_IN, type: db.STRING }
      }
    );
    return result.outBinds.invCount.val;
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// orderMessageConsumer - background
function orderMessageConsumer() {
  let order = null;
  let itemid = null;
  let invMsg = null;
  while (true) {
    // wait for and dequeue the next order message
    order = _dequeueOrderMessage(-1); // wait forever

    if (order === null) {
      conn.rollback;
      continue;
    }

    // fulfill the orders
    invMsg = fulfillOrder(order);

    // enqueue the inventory messages
    _enqueueInventoryMessage(invMsg);

    // commit
    conn.commit;
  }
}


// Business logic
function fulfillOrder(order) {
  let invMsg = {orderid: order.orderid, itemid: order.itemid, suggestiveSale: "beer"};

  // check the inventory
  conn.execute(
    "update inventory set inventorycount = inventorycount - 1 " +
    "where inventoryid = :itemid and inventorycount > 0 " +
    "returning inventorylocation into :inventorylocation",
    {
      itemid: { val: order.itemid, dir: db.BIND_IN, type: db.STRING },
      inventorylocation: { dir: db.BIND_OUT, type: db.STRING } 
    }
  );

  if (result.outBinds === undefined) {
    invMsg.inventorylocation = "inventorydoesnotexist";
  } else {
    invMsg.inventorylocation = result.outBinds.inventorylocation.val;
  }

  return invMsg;
}


// functions to enqueue and dequeue messages
function _enqueueInventoryMessage(invMsg) {
  conn.execute(
    "begin inventory_messaging.enqueue_inventory_message(json_object_t(:1)); end;",
    [invMsg.stringify()]
  );
}

function _dequeueOrderMessage(waitOption) {
  conn.execute(
    "begin :orderString := inventory_messaging.dequeue_order_message(:waitOption).to_string; end;", {
    orderString: { dir: db.BIND_OUT, type: db.STRING },
    waitOption: { val: waitOption, dir: db.BIND_IN, type: db.NUMBER }
  });
  return JSON.parse(result.outBinds.orderString.val);
}
