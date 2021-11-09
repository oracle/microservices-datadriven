## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
import traceback
import logging
from flask import Flask, request
from os import environ as env
import cx_Oracle
import simplejson
import consumer
import dbmgr

attempts = 2

dbmgr.setReadyFileName('/tmp/InventoryReady')

# Dict Factory for Rows
def makeDictFactory(cursor):
    columnNames = [d[0] for d in cursor.description]
    def createRow(*args):
        return dict(zip(columnNames, args))
    return createRow

# Parameters
debug_mode =          env.get("DEBUG_MODE", "1")

logger = logging.getLogger('python_inventory')
logger.setLevel(logging.ERROR if debug_mode == 0 else logging.DEBUG)
f = logging.FileHandler('python_inventory.log')
f.setLevel(logging.ERROR if debug_mode == 0 else logging.DEBUG)
c = logging.StreamHandler()
c.setLevel(logging.ERROR if debug_mode == 0 else logging.DEBUG)
formatter = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
f.setFormatter(formatter)
c.setFormatter(formatter)
logger.addHandler(f)
logger.addHandler(c)

# DB Manager thread
dbmgr.start("python_inventory.dbmgr")

# AQ Consumer Threads
consumer.start()

app = Flask(__name__)

@app.route("/inventory/<inventory_id>")
def get_inventory_id(inventory_id):
    conn = None
    for a in range(attempts):
        try:
            conn = dbmgr.acquireConn()
            cursor = conn.cursor()
            cursor.execute("select * from inventory where inventoryid = :id", [inventory_id])
            cursor.rowfactory = makeDictFactory(cursor)
            inventory = cursor.fetchone()
        except dbmgr.DatabaseDown as e:
            break
        except:
            logger.debug(traceback.format_exc())
            continue
        else:
            if a > 0:
                logger.debug("Retry Succeeded")
            return simplejson.dumps(inventory)
        finally:
            if conn:
                dbmgr.releaseConn(conn)

    return "", 500


