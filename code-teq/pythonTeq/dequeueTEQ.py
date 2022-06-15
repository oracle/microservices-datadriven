#
#  This sample demonstrates how to enqueue a message onto a TEQ using PL/SQL
#

#  There are various payload types supported, including user-defined object, raw, JMS and JSON.
#  This sample uses the JSON payload type.

#  Execute permission on dbms_aq is required.

import oracledb
from os import environ as env

# initialize the oracledb library, this will put us into 'thick mode' which is reqiured to use types
oracledb.init_oracle_client()

topicName = "my_teq"
consumerName = "my_subscriber"

# make sure that you set the environment variable DB_PASSWORD before running this
connection = oracledb.connect(dsn='localhost:1521/pdb1',user='pdbadmin',password=env.get('DB_PASSWORD'))

# get the JMS type
jmsType = connection.gettype("SYS.AQ$_JMS_TEXT_MESSAGE")
headerType = connection.gettype("SYS.AQ$_JMS_HEADER")
userPropType = connection.gettype("SYS.AQ$_JMS_USERPROPARRAY")

queue = connection.queue(topicName) #, jmsType)
queue.deqOptions.consumername = consumerName
queue.deqOptions.wait = 10

message = queue.deqOne()
connection.commit()
print("message: ", message.payload.decode(connection.encoding)) #TEXT_VC)