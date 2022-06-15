#
#  This sample demonstrates how to enqueue a message onto a TEQ using PL/SQL
#

#  There are various payload types supported, including user-defined object, raw, JMS and JSON.
#  This sample uses the JSON payload type.

#  Execute permission on dbms_aq is required.

import cx_Oracle
from os import environ as env

# make sure that you set the environment variable DB_PASSWORD before running this
connection = cx_Oracle.connect(dsn='localhost:1521/pdb1',user='pdbadmin',password=env.get('DB_PASSWORD'))

# get the JMS type
jmsType = connection.gettype("SYS.AQ$_JMS_TEXT_MESSAGE")
headerType = connection.gettype("SYS.AQ$_JMS_HEADER")
userPropType = connection.gettype("SYS.AQ$_JMS_USERPROPARRAY")

queue = connection.queue("my_json_teq", jmsType)

text = jmsType.newobject()
text.HEADER = headerType.newobject()
text.TEXT_VC = "hello from python"
text.TEXT_LEN = len(text.TEXT_VC)
text.HEADER.TYPE = "MyHeader"
text.HEADER.PROPERTIES = userPropType.newobject()

queue.enqOne(connection.msgproperties(payload=text))
connection.commit()
