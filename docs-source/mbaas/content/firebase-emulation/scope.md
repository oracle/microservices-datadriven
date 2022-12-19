---
title: "Implemented APIs"
---

This developer preview of Firebase API emulation includes only the following Implemented classes/methods:
 
* class Query
  * where()
  * orderBy()
  * limit()
  * get()
  * onSnapshot()
* class CollectionReference
  * add()
  * orderBy()
  * limit()
  * onSnapshot()
  * doc()
  * get()
  * where()
* class QueryDocumentSnapshot
  * data()
  * get()
* class DocumentReference
  * get()
  * collection()
* class QuerySnapshot
  * forEach()
* class DocumentSnapshot
  * data()
* class Firestore
  * collection()
  * runTransaction()
* class Transaction
  * get()
  * set()
  * update()

The diagram below shows relationships between these APIs:

![Firebase APIs emulated](../../firebase-apis-emulated.jpeg)