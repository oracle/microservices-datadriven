
Once you have completed the [setup](../setup) of the MBaaS, you can use the examples below to get started. 

## Creating an object

The most basic operation you can do is to create a new object in the database. The examples on this page use the REST API to access the MBaaS server. To create
an object, you perform an HTTP POST to the MBaaS endpoint `/parse/classes/` and append the name of the class of object you want to create, in this example the
object is a `GameScore`.  The content is provided in JSON format.  You need to provide the correct `APPLICATION_ID` and update the endpoint address to match
your environment:

```
curl -X POST \
     -H "X-Parse-Application-Id: APPLICATION_ID" \
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
     -H "X-Parse-Application-Id: APPLICATION_ID" \
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

**Note**: You can use any arbitrary string as your `APPLICATION_ID`. These will be used by your clients to authenticate with the Parse Server.  During creation of the MBaaS environment, you provided an Application ID as a configuration option.  If any call to the MBaaS Server does not use a valid Application ID, the call will be rejected with this error message:

```
{"error":"unauthorized"}
```

## Using the MBaaS Dashboard

The MBaaS installation includes a dashboard endpoint.  The MBaaS Dashboard is a web user interface for managing your MBaaS applications.

The dashboard URL was provided to you at the end of setup, and you chose the administrative user name and password during install.

To log into the dashboard, go to the provided URL and login with the admin credentials.

![Dashboard Login Page](../dashboard-login-page.png)

After you login, you will see the Landing Page which lists your applications.  Most likely, you will just have to one application that you created during
configuration of the MBaaS.  You can click on the application to see details and manage it.

![Dashboard Landing Page](../dashboard-landing-page.png)

Note the collections listed in the left hand pane. Click GameScore to see the data you created earlier.

![Dashboard GameScore page](../dashboard-gemscore.png)

