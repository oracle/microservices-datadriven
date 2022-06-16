#
#  This sample demonstrates how to enqueue a message onto a TEQ using Python
#

#  There are various payload types supported, including user-defined object, raw, JMS and JSON.
#  This sample uses the JMS payload type.

#  Execute permission on dbms_aq is required.
#  The python package 'oracledb' must be installed (e.g. with pip)

import oracledb
from os import environ as env

# initialize the oracledb library, this will put us into 'thick mode' which is reqiured to use types
oracledb.init_oracle_client()

# make sure that you set the environment variable DB_PASSWORD before running this
connection = oracledb.connect(dsn='localhost:1521/pdb1',user='pdbadmin',password=env.get('DB_PASSWORD'))

# get the JMS type
jmsType = connection.gettype("SYS.AQ$_JMS_TEXT_MESSAGE")
headerType = connection.gettype("SYS.AQ$_JMS_HEADER")
userPropType = connection.gettype("SYS.AQ$_JMS_USERPROPARRAY")

# get the TEQ
queue = connection.queue("my_jms_q", jmsType)

# prepare the message and headers
text = jmsType.newobject()
text.HEADER = headerType.newobject()
text.TEXT_VC = "hello from python"
text.TEXT_LEN = len(text.TEXT_VC)
text.HEADER.TYPE = "MyHeader"
text.HEADER.PROPERTIES = userPropType.newobject()

# enqueue the message
queue.enqOne(connection.msgproperties(payload=text,recipients=["my_subscriber"]))
connection.commit()
