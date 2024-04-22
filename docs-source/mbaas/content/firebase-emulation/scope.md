---
title: "Implemented APIs"
---

# Implemented APIs

This _Developer_ _Preview_ of the Firebase API emulation includes only the following implemented classes and methods:
 
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

Next, go to the [Dashboard](../dashboard/) page to learn more about the dashboard.
