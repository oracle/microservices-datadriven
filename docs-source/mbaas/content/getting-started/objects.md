---
title: "Working with Objects"
---

The Oracle Backend for Parse Platform stores your data in objects. Each object is an instance of a named class. A class has certain properties or fields. You
create a class by creating the first object in that class. You define the fields by using them. Once a class has a field with a certain type, you
cannot change that field type while objects using it exist.

## Creating an Object

The most basic operation that you can do is to create a new object in the database. The following examples use the Representational State Transfer (REST) API to access
the Parse Server. To create
an object, perform an HTTP `POST` to the Parse endpoint `/parse/classes/` and append the name of the class of the object that you want to create. In this example, the
object is `GameScore`.  The content is provided in JavaScript Object Notation (JSON) format. Provide the correct `APPLICATION_ID` and update the endpoint address to match
your environment. For example:

```
curl -X POST \
     -H "X-Parse-Application-Id: COOLAPPV100" \
     -H "Content-Type: application/json" \
     -d '{"score":100000,"playerName":"test user","cheatmode":false}' \
     http://1.2.3.4/parse/classes/GameScore
```

This command creates an entry for `GameScore` in the schema collection and creates or updates the `GameScore` collection with your new object. It returns
the `objectId` for the newly created object. For example:

```
{"objectId":"Ts9B8JSBBX","createdAt":"2022-12-12T14:47:28.431Z"}
```

The `objectId` is the unique identifier for a document in the collection.  

## Retrieving an Object 

To retrieve the newly created object, use the HTTP `GET` API as shown in the following example.  Append the `objectId` to the end of the URL. Update the command
with your `APPLICATION_ID` and endpoint address. For example:

```
curl -X GET \
     -H "X-Parse-Application-Id: COOLAPPV100" \
     http://1.2.3.4/parse/classes/GameScore/Ts9B8JSBBX
# output (formatted):
{
    "score":100000,
    "playerName":"test user",
    "cheatmode":false,
    "updatedAt":"2022-12-12T14:47:28.431Z",
    "createdAt":"2022-12-12T14:47:28.431Z",
    "objectId":"Ts9B8JSBBX"
}
```

**NOTE:** You can use any arbitrary string as your `APPLICATION_ID`. These are used by your clients to authenticate with the Parse Server. During creation of
the Oracle Backend for Parse Platform environment, you provided an application ID as a configuration option. If any call to the Parse Server does not use a
valid application ID, the call is rejected and returns this error message:

```
{"error":"unauthorized"}
```

## More information

Learn more about [working with objects](https://docs.parseplatform.org/parse-server/guide/#getting-started) in the Parse Server documentation.

Next, go to the [Using the Parse Dashboard](../getting-started/dashboard/) page to learn how to use the dashboard.
