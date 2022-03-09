// Copyright (c) 2021 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

// addInventory - API
function addInventory(conn, itemid) {
  try {
    conn.execute( "update inventory set inventorycount=inventorycount + 1 where inventoryid = :1;", [itemid]);
    conn.commit;
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// removeInventory - API
function removeInventory(conn, itemid) {
  try {
    conn.execute( "update inventory set inventorycount=inventorycount - 1 where inventoryid = :1;", [itemid]);
    conn.commit;
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// getInventory - API
function getInventory(conn, itemid) {
  try {
    let result = conn.execute( "select inventorycount into :invCount from inventory where inventoryid = :itemid;", {
      invCount: { dir: oracledb.BIND_OUT, type: oracledb.STRING },
      itemid: { val: itemid, dir: oracledb.BIND_IN, type: oracledb.STRING }
    });
    return result.outBinds.invCount.val;
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// orderMessageConsumer - background
function orderMessageConsumer(conn) {
  let order = null;
  let itemid = null;
  let invMsg = null;
  while (true) {
    -- wait for and dequeue the next order message
    order := _dequeueOrderMessage(conn, -1); // wait forever

    if (order === null) {
      conn.rollback;
      continue;
    }

    -- fulfill the orders
    invMsg = fulfillOrder(conn, order);

    -- enqueue the inventory messages
    _enqueueInventoryMessage(conn, invMsg);

    -- commit
    conn.commit;
  }
}


// Business logic
function fulfillOrder(conn, order) {
  let invMsg = {orderid: order.orderid, itemid: order.itemid, suggestiveSale: "beer"};

  -- check the inventory
  conn.execute(
    "update inventory set inventorycount = inventorycount - 1
      where inventoryid = :itemid and inventorycount > 0
      returning inventorylocation into :inventorylocation;",
    {
      itemid: { val: order.itemid, dir: oracledb.BIND_IN, type: oracledb.STRING },
      inventorylocation: { dir: oracledb.BIND_OUT, type: oracledb.STRING } }
  );

  if (result.outBinds === undefined) {
    invMsg.inventorylocation = "inventorydoesnotexist";
  } else {
    invMsg.inventorylocation = result.outBinds.inventorylocation.val;
  }

  return invMsg;
}


// functions to enqueue and dequeue messages
function _enqueueInventoryMessage(conn, invMsg) {
  conn.execute(
    "begin order_messaging.enqueue_order_message(json_object_t(:1)); end;",
    [invMsg.stringify()]
  );
}

function _dequeueOrderMessage(conn, waitOption) {
  conn.execute(
    "begin :orderString := order_messaging.dequeue_inventory_message(:waitOption).to_string; end;", {
    orderString: { dir: oracledb.BIND_OUT, type: oracledb.STRING },
    waitOption: { val: waitOption, dir: oracledb.BIND_IN, type: oracledb.NUMBER }
  });
  return JSON.parse(result.outBinds.orderString.val);
}
