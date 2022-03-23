// Copyright (c) 2021 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

// global constants
const db = require("mle-js-oracledb");
const bindings = require("mle-js-bindings");
const conn = db.defaultConnection();

// addInventory - API
function addInventory(itemid) {
  let invCount = "invalid inventory item";
  try {
    let result = conn.execute( 
      "update inventory set inventorycount=inventorycount + 1 where inventoryid = :itemid " +
      "returning to_char(inventorycount) into :invCount", 
      {
        itemid: { val: itemid, dir: db.BIND_IN, type: db.STRING },
        invCount: { dir: db.BIND_OUT, type: db.STRING }
      }
    );

    if (result.rowsAffected > 0) {
      invCount = result.outBinds.invCount[0];
    }

    conn.commit;

    return invCount;
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// removeInventory - API
function removeInventory(itemid) {
  let invCount = "invalid inventory item";
  try {
    let result = conn.execute( 
      "update inventory set inventorycount=inventorycount - 1 where inventoryid = :itemid " +
      "returning to_char(inventorycount) into :invCount", 
      {
        itemid: { val: itemid, dir: db.BIND_IN, type: db.STRING },
        invCount: { dir: db.BIND_OUT, type: db.STRING }
      }
    );

    if (result.rowsAffected > 0) {
      invCount = result.outBinds.invCount[0];
    }

    conn.commit;

    return invCount;
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// getInventory - API
function getInventory(itemid) {
  try {
    let rows = conn.execute( 
      "select to_char(inventorycount) as invcount from inventory where inventoryid = :itemid", 
      [itemid]
    ).rows;
    if (rows.length > 0) {
      return rows[0][0];
    } else {
      return "invalid inventory item";
    }
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// orderMessageConsumer - background
function orderMessageConsumer() {
  let order = null;
  let invMsg = null;

  // wait for and dequeue the next order message
  order = _dequeueOrderMessage(-1); // wait forever

  if (order === null) {
    conn.rollback;
    return;
  }

  // fulfill the orders
  invMsg = fulfillOrder(order);

  // enqueue the inventory messages
  _enqueueInventoryMessage(invMsg);

  // commit
  conn.commit;
}


// Business logic
function fulfillOrder(order) {
  let invMsg = {orderid: order.orderid, itemid: order.itemid, suggestiveSale: "beer"};

  // check the inventory
  let result = conn.execute(
    "update inventory set inventorycount = inventorycount - 1 " +
    "where inventoryid = :itemid and inventorycount > 0 " +
    "returning inventorylocation into :inventorylocation",
    {
      itemid: { val: order.itemid, dir: db.BIND_IN, type: db.STRING },
      inventorylocation: { dir: db.BIND_OUT, type: db.STRING } 
    }
  );

  if (result.rowsAffected === 0) {
    invMsg.inventorylocation = "inventorydoesnotexist";
  } else {
    invMsg.inventorylocation = result.outBinds.inventorylocation[0];
  }

  return invMsg;
}

// functions to enqueue and dequeue messages
function _enqueueInventoryMessage(invMsg) {
  conn.execute(
    "begin inventory_messaging.enqueue_inventory_message(json_object_t(:1)); end;",
    [JSON.stringify(invMsg)]
  );
}

function _dequeueOrderMessage(waitOption) {
  let result = conn.execute(
    "begin :orderString := inventory_messaging.dequeue_order_message(:waitOption).to_string; end;", {
    orderString: { dir: db.BIND_OUT, type: db.STRING, maxSize: 400 },
    waitOption: { val: waitOption, dir: db.BIND_IN, type: db.NUMBER }
  });
  return JSON.parse(result.outBinds.orderString);
}
