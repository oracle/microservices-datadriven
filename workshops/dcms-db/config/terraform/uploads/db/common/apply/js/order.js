// Copyright (c) 2021 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


// global constants
const db = require("mle-js-oracledb");
const bindings = require("mle-js-bindings");
const conn = db.defaultConnection();

// placeOrder - API
function placeOrder(order) {
  try {
    order.status = "pending";
    order.inventorylocation = "";
    order.suggestivesale = "";

    // insert the order object
    _insertOrder(order);

    // send the order message
    _enqueueOrderMessage(order);

    // commit
    conn.commit;

    return order;

  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// showOrder - API
function showOrder(orderid) {
  return _getOrder(orderid);
}

// deleteAllOrders
function deleteAllOrders() {
  try {
    _deleteAllOrders(conn);
  } catch(error) {
    conn.rollback;
    throw error;
  }
}

// inventoryMessageConsumer - background
function inventoryMessageConsumer() {
  let invMsg = null;
  let order =  null;

  // wait for and dequeue the next order message
  invMsg = _dequeueInventoryMessage(-1); // wait forever

  if (invMsg === null) {
    conn.rollback;
    return;
  }

  // get the existing order
  order = _getOrder(invMsg.orderid);

  // update the order based on inv message
  if (invMsg.inventorylocation === "inventorydoesnotexist") {
    order.status = "failed inventory does not exist";
  } else {
    order.status = "success inventory exists";
    order.inventorylocation = invMsg.inventorylocation;
    order.suggestivesale = invMsg.suggestiveSale;
  }

  // persist the updates
  _updateOrder(order);

  // commit
  conn.commit;
}


// functions to access the order collection
function _insertOrder(order) {
  conn.execute( 
    "begin order_collection.insert_order(json_object_t(:1)); end;", 
    [JSON.stringify(order)]
  );
}

function _updateOrder(order) {
  conn.execute( 
    "begin order_collection.update_order(json_object_t(:1)); end;", 
    [JSON.stringify(order)]
  );
}

function _getOrder(orderid) {
  let result = conn.execute( 
    "begin :orderString := order_collection.get_order(:orderid).to_string; end;", 
    {
      orderString: { dir: db.BIND_OUT, type: db.STRING, maxSize: 400 },
      orderid: { val: orderid, dir: db.BIND_IN, type: db.STRING }
    }
  );
  return JSON.parse(result.outBinds.orderString);
}

function _deleteAllOrders() {
  conn.execute("begin order_collection.delete_all_orders; end;");
}


// functions to enqueue and dequeue messages
function _enqueueOrderMessage(order) {
  conn.execute( 
    "begin order_messaging.enqueue_order_message(json_object_t(:1)); end;", 
    [JSON.stringify(order)]
  );
}

function _dequeueInventoryMessage(waitOption) {
  let result = conn.execute(
    "begin :invMsgString := order_messaging.dequeue_inventory_message(:waitOption).to_string; end;", 
    {
      invMsgString: { dir: db.BIND_OUT, type: db.STRING, maxSize: 400 },
      waitOption: { val: waitOption, dir: db.BIND_IN, type: db.NUMBER }
    }
  );
  return JSON.parse(result.outBinds.invMsgString);
}
