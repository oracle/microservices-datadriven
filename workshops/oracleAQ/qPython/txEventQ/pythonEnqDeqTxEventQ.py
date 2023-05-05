import os
import logging
from os import environ as env
import cx_Oracle
import threading
import time
import oci
import base64

connection = cx_Oracle.connect(dsn=env.get('DB_ALIAS'))
cursor = connection.cursor()

#ADT payload
book_type = connection.gettype("PYTHON_TxEventQ_MESSAGE_TYPE")
adtQueue = connection.queue("PYTHON_TxEventQ_ADT", book_type)

book = book_type.newobject()
book.TITLE = "Quick Brown Fox"
book.AUTHORS = "The Dog"
book.PRICE = 123
props = connection.msgproperties(payload=book, correlation="correlation-py", expiration=30, priority=7)

print("1) Sample for Classic Queue : ADT payload")
print("Enqueue one message with ADT payload : ",book.TITLE)
adtQueue.enqOne(props)
connection.commit()
print("Enqueue Done!!!")

#deqOptions should have consumername in case of multiconsumer queue
adtQueue.deqOptions.consumername = "PYTHON_TxEventQ_SUBSCIBER_ADT"
adtQueue.deqOptions.wait = cx_Oracle.DEQ_NO_WAIT
adtQueue.deqOptions.navigation = cx_Oracle.DEQ_FIRST_MSG
adtMsg = adtQueue.deqOne()
connection.commit()
print("Dequeued message with ADT payload : ",adtMsg.payload.TITLE)
print("Dequeue Done!!!") 
print("-----------------------------------------------------------------")

#RAW PAYLOAD
print("\n2) Sample for Classic queue : RAW payload")

rawQueue = connection.queue("PYTHON_TxEventQ_RAW")
PAYLOAD_DATA = [
        "The first message"
]
for data in PAYLOAD_DATA:
    print("Enqueue message with RAW payload : ",data)
    rawQueue.enqone(connection.msgproperties(payload=data))
connection.commit()
print("Enqueue Done!!!")	

rawQueue.deqOptions.consumername = "PYTHON_TxEventQ_SUBSCIBER_RAW"
rawQueue.deqOptions.wait = cx_Oracle.DEQ_NO_WAIT
rawQueue.deqOptions.navigation = cx_Oracle.DEQ_FIRST_MSG
rawMsg = rawQueue.deqOne()
connection.commit()
print(rawMsg.payload.decode(connection.encoding))
print("Dequeued message with RAW payload : ",rawMsg.payload)
print("Dequeue Done!!!") 
print("-----------------------------------------------------------------")

print("\n3) Sample for Classic queue : JMS payload")
#get the JMS type
jmsType = connection.gettype("SYS.AQ$_JMS_TEXT_MESSAGE")
headerType = connection.gettype("SYS.AQ$_JMS_HEADER")
user_prop_Type = connection.gettype("SYS.AQ$_JMS_USERPROPARRAY")

jmsQueue = connection.queue("PYTHON_TxEventQ_JMS",jmsType)
#create python object for JMS type
text = jmsType.newobject()
text.HEADER = headerType.newobject()
text.TEXT_VC = "JMS text message"
text.TEXT_LEN = 20
text.HEADER.APPID = "py-app-1"
text.HEADER.GROUPID = "py-grp-1"
text.HEADER.GROUPSEQ = 1
text.HEADER.PROPERTIES = user_prop_Type.newobject()
print("Enqueue one message with JMS payload : ",text.TEXT_VC)
jmsQueue.enqOne(connection.msgproperties(payload=text))
connection.commit()
print("Enqueue Done!!!")

jmsQueue.deqOptions.consumername = "PYTHON_TxEventQ_SUBSCIBER_JMS"
jmsQueue.deqOptions.wait = cx_Oracle.DEQ_NO_WAIT
jmsQueue.deqOptions.navigation = cx_Oracle.DEQ_FIRST_MSG
jmsMsg = jmsQueue.deqOne()
connection.commit()
print("Dequeued message with JMS payload :",jmsMsg.payload.TEXT_VC)
print("Dequeue Done!!!") 
print("-----------------------------------------------------------------")
