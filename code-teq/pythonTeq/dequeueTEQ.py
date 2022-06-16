# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

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

topicName = "my_jms_q"
consumerName = "my_subscriber"

# make sure that you set the environment variable DB_PASSWORD before running this
connection = oracledb.connect(dsn='localhost:1521/pdb1',user='pdbadmin',password=env.get('DB_PASSWORD'))

# get the JMS types
jmsType = connection.gettype("SYS.AQ$_JMS_TEXT_MESSAGE")
headerType = connection.gettype("SYS.AQ$_JMS_HEADER")
userPropType = connection.gettype("SYS.AQ$_JMS_USERPROPARRAY")

# get the TEQ and set up the dequeue options
queue = connection.queue(topicName, jmsType)
queue.deqOptions.consumername = consumerName
queue.deqOptions.wait = 10  # wait 10 seconds before giving up if no message received 

# perform the dequeue
message = queue.deqOne()
connection.commit()

# print out the payload
print("message: ", message.payload.TEXT_VC)