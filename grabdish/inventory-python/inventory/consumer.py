
##
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
import traceback
import logging
import time
import cx_Oracle
import simplejson
import threading
import dbmgr
from os import environ as env


logger = logging.getLogger('python_inventory.consumer')

aq_consumer_threads = int(env.get("AQ_CONSUMER_THREADS", "1"))
queue_owner =         env.get("QUEUE_OWNER","PYTHON_AQ")

def start():
    for x in range(aq_consumer_threads):
        t = threading.Thread(None, run)
        t.daemon = True
        t.start()

def run():
    sql = """update inventory set inventorycount = inventorycount - 1
             where inventoryid = :inventoryid and inventorycount > 0
             returning inventorylocation into :inventorylocation"""

    conn = None
    while True: # retry if it fails
        try:
            conn = dbmgr.acquireConn()
            orderQueue = conn.queue(queue_owner + ".orderqueue", conn.gettype("SYS.AQ$_JMS_TEXT_MESSAGE"))
            orderQueue.deqoptions.navigation = cx_Oracle.DEQ_FIRST_MSG  # Required for TEQ
            orderQueue.deqoptions.consumername = "inventory_service"
            inventoryQueue = conn.queue(queue_owner + ".inventoryqueue", conn.gettype("SYS.AQ$_JMS_TEXT_MESSAGE"))
            cursor = conn.cursor()
            # Loop requesting inventory requests from the order queue
            while True:
                # Dequeue the next event from the order queue
                conn.autocommit = False
                payload =orderQueue.deqOne().payload
                logger.debug(payload.TEXT_VC)
                orderInfo = simplejson.loads(payload.TEXT_VC)

                # Update the inventory for this order.  If no row is updated there is no inventory.
                ilvar = cursor.var(str)
                cursor.execute(sql, [orderInfo["itemid"], ilvar])

                # Enqueue the response on the inventory queue
                payload = conn.gettype("SYS.AQ$_JMS_TEXT_MESSAGE").newobject()
                payload.TEXT_VC = simplejson.dumps(
                    {'orderid': orderInfo["orderid"],
                     'itemid': orderInfo["itemid"],
                     'inventorylocation': ilvar.getvalue(0)[0] if cursor.rowcount == 1 else "inventorydoesnotexist",
                     'suggestiveSale': "beer"})
                payload.TEXT_LEN = len(payload.TEXT_VC)
                inventoryQueue.enqOne(conn.msgproperties(payload = payload))
                conn.commit()

        except dbmgr.DatabaseDown as e:
            time.sleep(1)
            continue  # Retry after waiting a while

        except:
            logger.debug(traceback.format_exc())
            continue  # Retry immediately

        finally:
            if conn:
                dbmgr.releaseConn(conn)

