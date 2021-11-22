## Copyright (c) 2021 Oracle and/or its affiliates.
import traceback
import logging
from flask import Flask, request
from os import environ as env
import cx_Oracle
import simplejson
import WineFoodPairings

# Parameters
debug_mode =          env.get("DEBUG_MODE", "1")

logger = logging.getLogger('python_foodwinepairing')
logger.setLevel(logging.ERROR if debug_mode == 0 else logging.DEBUG)
f = logging.FileHandler('python_foodwinepairing.log')
f.setLevel(logging.ERROR if debug_mode == 0 else logging.DEBUG)
c = logging.StreamHandler()
c.setLevel(logging.ERROR if debug_mode == 0 else logging.DEBUG)
formatter = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
f.setFormatter(formatter)
c.setFormatter(formatter)
logger.addHandler(f)
logger.addHandler(c)


app = Flask(__name__)

@app.route("/foodwinepairing/<item_id>")
def get_recommended_wines(item_id):
    try:
        '''
            TODO : Call the wine pairing.py here and get the recommended wines
        '''
        print('In app.py, get_recommended_wines() => Item Passed : ', item_id)
        wines = WineFoodPairings.getRecommendedWines(item_id)
        print('In app.py, Recommended Wine Names : ', wines)
        return simplejson.dumps(wines)
    except:
        print('In app.py Exception')
        logger.debug(traceback.format_exc())
