// Copyright (c) 2021 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

// placeOrder - API
function placeOrder(conn, order) {
  try {
    order.status = "pending";
    order.inventorylocation = "";
    order.suggestivesale = "";

    // insert the order object
    _insertOrder(conn, order);

    // send the order message
    _enqueueOrderMessage(conn, order);

    // commit
    conn.commit;

    return order;

  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// showOrder - API
function showOrder(conn, orderid) {
  return _getOrder(conn, orderid);
}

// deleteAllOrders
function deleteAllOrders(conn) {
  try {
    _deleteAllOrders(conn);
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// inventoryMessageConsumer - background
function inventoryMessageConsumer(conn) {
  let invMsg = null;
  let order =  null;
  while (true) {
    // wait for and dequeue the next order message
    invMsg = _dequeueInventoryMessage(conn, -1); // wait forever

    if (invMsg === null) {
      conn.rollback;
      continue;
    }

    // get the existing order
    order = _getOrder(conn, invMsg.orderid);

    // update the order based on inv message
    if (invMsg.inventorylocation === "inventorydoesnotexist") {
      order.status = "failed inventory does not exist";
    } else {
      order.status = "success inventory exists";
      order.inventorylocation = invMsg.inventorylocation;
      order.suggestivesale = invMsg.suggestiveSale;
    }

    // persist the updates
    _updateOrder(conn, order);

    // commit
    conn.commit;
  }
}


// functions to access the order collection
function _insertOrder(conn, order) {
  conn.execute( "begin order_collection.insert_order(json_object_t(:1)); end;", [order.stringify()]);
}

function _updateOrder(conn, order) {
  conn.execute( "begin order_collection.update_order(json_object_t(:1)); end;", [order.stringify()]);
}

function _getOrder(conn, orderid) {
  let result = conn.execute( "begin :orderString := order_collection.get_order(:orderid).to_string; end;", {
    orderString: { dir: oracledb.BIND_OUT, type: oracledb.STRING },
    orderid: { val: orderid, dir: oracledb.BIND_IN, type: oracledb.STRING }
  });
  return JSON.parse(result.outBinds.orderString.val);
}

function _deleteAllOrders(conn) {
  conn.execute("begin order_collection.delete_all_orders; end;");
}


// functions to enqueue and dequeue messages
function _enqueueOrderMessage(conn, order) {
  conn.execute( "begin order_messaging.enqueue_order_message(json_object_t(:1)); end;", [order.stringify()]);
}

function _dequeueInventoryMessage(conn, waitOption) {
  let result = conn.execute(
    "begin :invMsgString := order_messaging.dequeue_inventory_message(:waitOption).to_string; end;", {
    invMsgString: { dir: oracledb.BIND_OUT, type: oracledb.STRING },
    waitOption: { val: waitOption, dir: oracledb.BIND_IN, type: oracledb.NUMBER }
  });
  return JSON.parse(result.outBinds.invMsgString.val);
}
