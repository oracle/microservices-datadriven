---
title: "Working with Objects"
---

The Oracle Backend for Parse Platform stores your data in objects, each object is an instance of a named class.  A class has certain properties, or fields. You create a class
by just creating the first object in that class.  You define the fields by just using them.  Once a class has a field with a certain type, you
cannot change that field type while objects using it exist.

## Creating an object

The most basic operation you can do is to create a new object in the database. The examples on this page use the REST API to access the Parse Server. To create
an object, you perform an HTTP POST to the Parse endpoint `/parse/classes/` and append the name of the class of object you want to create, in this example the
object is a `GameScore`.  The content is provided in JSON format.  You need to provide the correct `APPLICATION_ID` and update the endpoint address to match
your environment:

```
curl -X POST \
     -H "X-Parse-Application-Id: COOLAPPV100" \
     -H "Content-Type: application/json" \
     -d '{"score":100000,"playerName":"test user","cheatmode":false}' \
     http://1.2.3.4/parse/classes/GameScore
```

This command will create an entry for `GameScore` in the Schema collection and will create/update the GameScore collection with your new object. It will return
the `objectId` for the newly created object: 

```
{"objectId":"Ts9B8JSBBX","createdAt":"2022-12-12T14:47:28.431Z"}
```

`objectId` is the unique identifier for the a document in the collection.  

## Retrieving an object 

To retrieve the newly created object, use the HTTP GET API as shown below.  Append the `objectId` to the end of the URL.  As above, update the command
with your `APPLICATION_ID` and endpoint address:

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

**Note**: You can use any arbitrary string as your `APPLICATION_ID`. These will be used by your clients to authenticate with the Parse Server.  During creation of the Oracle Backend for Parse Platform environment, you provided an Application ID as a configuration option.  If any call to the Parse Server does not use a valid Application ID, the call will be rejected with this error message:

```
{"error":"unauthorized"}
```

## More information

Learn more about [working with objects](https://docs.parseplatform.org/parse-server/guide/#getting-started) in the Parse Server documentation.



