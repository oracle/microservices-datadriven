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
book_type = connection.gettype("ADT_BOOK")
queue = connection.queue("PYTHON_ADT_Q", book_type)

book = book_type.newobject()
book.TITLE = "Quick Brown Fox"
book.AUTHORS = "The Dog"
book.PRICE = 123
props = connection.msgproperties(payload=book, correlation="correlation-py", expiration=30, priority=7)

print("1) Sample for Classic Queue : ADT payload")
print("Enqueue one message with ADT payload : ",book.TITLE)
queue.enqOne(props)
connection.commit()
print("Enqueue Done!!!")

#deqOptions should have consumername in case of multiconsumer queue
#queue.deqOptions.consumername = "PYTHON_ADT_SUBSCIBER"
options = connection.deqoptions()
options.wait = cx_Oracle.DEQ_NO_WAIT
msg = queue.deqOne()
connection.commit()
print("Dequeued message with ADT payload : ",msg.payload.TITLE)
print("Dequeue Done!!!") 
print("-----------------------------------------------------------------")

#RAW PAYLOAD
print("\n2) Sample for Classic queue : RAW payload")

queue = connection.queue("PYTHON_RAW_Q")
PAYLOAD_DATA = [
        "The first message"
]
for data in PAYLOAD_DATA:
    print("Enqueue message with RAW payload : ",data)
    queue.enqone(connection.msgproperties(payload=data))

connection.commit()
print("Enqueue Done!!!")	

msg = queue.deqOne()
connection.commit()
print(msg.payload.decode(connection.encoding))
print("Dequeued message with RAW payload : ",msg.payload)
print("Dequeue Done!!!") 
print("-----------------------------------------------------------------")

print("\n3) Sample for Classic queue : JMS payload")
#get the JMS type
jmsType = connection.gettype("SYS.AQ$_JMS_TEXT_MESSAGE")
headerType = connection.gettype("SYS.AQ$_JMS_HEADER")
user_prop_Type = connection.gettype("SYS.AQ$_JMS_USERPROPARRAY")

queue = connection.queue("PYTHON_JMS_Q",jmsType)
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
queue.enqOne(connection.msgproperties(payload=text))
connection.commit()
print("Enqueue Done!!!")

msg = queue.deqOne()
connection.commit()
print("Dequeued message with JMS payload :",msg.payload.TEXT_VC)
print("Dequeue Done!!!") 
print("-----------------------------------------------------------------")
