---
title: "Users, Roles and ACLs"
---

# Users, Roles and ACLs

## Creating Users

You can create a user with this Representational State Transfer (REST) API. You must provide the correct `APPLICATION_ID` and endpoint for your environment. For example:

```
curl -X POST \
    -H "X-Parse-Application-Id: COOLAPPV100" \
    -H "X-Parse-Revocable-Session: 1" \
    -H "Content-Type: application/json" \
    -d '{"username":"newuser","password":"newpassword","phone":"415-392-0202"}' \
    http://1.2.3.4/parse/users

# output (formatted):
{
    "objectId":"DrIxj80hAf",
    "createdAt":"2022-12-12T18:11:18.497Z",
    "sessionToken":"r:6cad2f1fcd7de36e68ed86e3d215d324"
}
```

**NOTE:** Email server integration is not available in this _Developer_ _Preview_. Verifying email and the password reset functionality is not supported at this time.

Learn more about users in the [Parse Server documentation](https://docs.parseplatform.org/rest/guide/#users)


## Creating Roles

You can create a role with this REST API. You must provide the correct `APPLICATION_ID` and endpoint for your environment. For example:

```
curl -X POST \
    -H "X-Parse-Application-Id: COOLAPPV100" \
    -H "Content-Type: application/json" \
    -d '{"name": "Moderators","ACL": {"*": {"read": true}}}' \
    http://1.2.3.4/parse/roles

# output (formatted):
{
    "objectId":"otUtMWXca3",
    "createdAt":"2022-12-12T18:46:27.341Z"
}
```

Learn more about roles in the [Parse Server documentation](https://docs.parseplatform.org/rest/guide/#roles)


## Using Access Control Lists (ACLs)

Parse ACLs are implemented as part of the API and can be specified on most requests.

The following examples use the `GameScore` collection that you created earlier. Also, the examples focus on the delete function which requires the write permission.

Learn more about ACLs in the [Parse Server documentation](https://docs.parseplatform.org/parse-server/guide/#object-level-access-control)

### GameScore With No ACLs

* Create a `GameScore` document using these commands:

    ```
    curl -X POST \
         -H "X-Parse-Application-Id: COOLAPPV100" \
         -H "Content-Type: application/json" \
         -d '{"playerName":"Mom Staples","cheatmode":false, "score":25}' \
         http://1.2.3.4/parse/classes/GameScore
    
    # output (formatted):
    {
        "objectId":"BLxUYqfh6E",
        "createdAt":"2022-09-23T13:48:08.834Z"
    }
    ```

    This creates a document similar to the following: 

    ```
    {
        "playerName": "Mom Staples",
        "cheatmode": false,
        "score": 25,
        "updatedAt": "2022-09-23T13:48:08.834Z",
        "createdAt": "2022-09-23T13:48:08.834Z",
        "_id": "BLxUYqfh6E"
    }
    ```
    Note that no ACLs are associated with this object.

* Delete `GameScore` without an ACL using these commands:

    ```
    curl -X DELETE \
         -H "X-Parse-Application-Id: COOLAPPV100" \
         http://1.2.3.4/parse/classes/GameScore/BLxUYqfh6E

    # output
    {}
    ```

    The document is deleted. You can verify this using the `GET` API, the dashboard, or by looking in the JavaScript Object Notation (JSON) collection in the database.

### GameScore With User ACL

* Create a `GameScore` document with a specific user that has read/write access. For example:

    ```
    curl -X POST \
         -H "X-Parse-Application-Id: COOLAPPV100" \
         -H "Content-Type: application/json" \
         http://1.2.3.4/parse/classes/GameScore \
         --data-binary @- << EOF
         {
           "playerName":"Pop Staples",
           "cheatmode":false, 
           "score":2500,  
           "ACL": { 
             "*": {
               "read": true
             },
             "E3t4Iid6XN": {
               "read" :true, 
               "write": true 
             }
           }
         }
         EOF


    # output (formatted):
    {
        "objectId":"9xTZkqjTwB",
        "createdAt":"2022-09-23T13:55:58.787Z"
    }
    ```

    This creates a document similar to the following:

    ```
    {
        "playerName": "Pop Staples",
        "cheatmode": false,
        "score": 2500,
        "updatedAt": "2022-09-23T13:55:58.787Z",
        "createdAt": "2022-09-23T13:55:58.787Z",
        "_id": "9xTZkqjTwB",
        "_wperm": [
            "E3t4Iid6XN"
        ],
        "_rperm": [
            "*",
            "E3t4Iid6XN"
        ],
        "_acl": {
            "E3t4Iid6XN": {
                "w": true,
                "r": true
            },
            "*": {
                "r": true
            }
        }
    }
    ```

    **NOTE:** Specifying an ACL creates the internal `_rperm` and `_wperm`. These are not accessible through the API and are Parse internal implementation data.

* Delete a `GameScore` document with a specific user that has read/write access.

    To delete a document that has ACLs, a caller needs to specify the session token that is obtained by logging in. For example:

    ```
    curl -X POST \
         -H "X-Parse-Application-Id: COOLAPPV100" \
         -H "X-Parse-Revocable-Session: 1" \
         -H "Content-Type: application/json" \
         -d '{"username":"nyg","password":"password"}' \
         http://1.2.3.4/parse/login

    # output (formatted):
    {
        "username":"nyg",
        "phone":"111-111-1111",
        "updatedAt":"2022-09-21T15:06:49.526Z",
        "createdAt":"2022-09-21T15:06:49.526Z",
        "objectId":"E3t4Iid6XN",
        "ACL":{
            "*":{
                "read":true
            },
            "E3t4Iid6XN":{
                "read":true,
                "write":true
            }
        },
        "sessionToken":"r:e8256f575a826b64a91a18d6ad21911b"
    }
    ```

    As you can see, user `nyg` has ID `E3t4Iid6XN` which matches the `_wperm` in the document.

    To delete the document, use the `DELETE` API with the `sessionToken` associated with the user. For example:

    ```
    curl -X DELETE \
         -H "X-Parse-Application-Id: COOLAPPV100" \
         -H "X-Parse-Session-Token: r:9431c553bb56f21c0a2853b18b5df37d" \
         http://1.2.3.4/parse/classes/GameScore/9xTZkqjTwB

    # output
    {}
    ```


### GameScore With Roles ACL

Roles work in a similar fashion to Users. It is assumed that, for this example, the User `bruce` has been associated with the role `Admins`.

* Create a `GameScore` document with a specific role that has read/write access. For example:

    ```
    curl -X POST \
    -H "X-Parse-Application-Id: COOLAPPV100" \
    -H "Content-Type: application/json" \
    http://1.2.3.4/parse/classes/GameScore \
    --data-binary @- << EOF
    {
      "playerName":"Aaron Judge",
      "cheatmode":false, 
      "score":64, 
      "ACL": {
        "*": {
          "read": true
        },
        "role:Admins": {
          "read" :true, 
          "write": true 
        }
      }
    }
    EOF

    # output (formatted)
    {
        "objectId":"LkTqWJKWw1",
        "createdAt":"2022-09-23T17:39:20.115Z"
    }
    ```

    This creates a document similar to the following: 

    ```
        {
        "playerName": "Aaron Judge",
        "cheatmode": false,
        "score": 64,
        "updatedAt": "2022-09-23T17:39:20.115Z",
        "createdAt": "2022-09-23T17:39:20.115Z",
        "_id": "LkTqWJKWw1",
        "_wperm": [
            "role:Admins"
        ],
        "_rperm": [
            "*",
            "role:Admins"
        ],
        "_acl": {
            "role:Admins": {
                "w": true,
                "r": true
            },
            "*": {
                "r": true
            }
        }
    }
    ```

*  To delete this document, a caller must get the session token for a user that has the `Admins` role by logging in. For example:

    ```
    curl -X POST \
    -H "X-Parse-Application-Id: COOLAPPV100" \
    -H "X-Parse-Revocable-Session: 1" \
    -H "Content-Type: application/json" \
    -d '{"username":"bruce","password":"password"}' \
    http://1.2.3.4/parse/login

    # output (formatted)
    {
      "username":"bruce",
      "phone":"222-222-2222",
      "updatedAt":"2022-09-21T16:26:32.948Z",
      "createdAt":"2022-09-21T16:26:32.948Z",
      "objectId":"tE8wEhXmJg",
      "ACL": {
        "*": {
            "read":true
        },
        "tE8wEhXmJg":{
            "read":true,
            "write":true
        }
      },
      "sessionToken":"r:9805595b4a73c8d2135ae9e70bb885c6"
    }
    ```

    The session token must be supplied in the `DELETE` API call. For example:

    ```
    curl -X DELETE \
    -H "X-Parse-Application-Id: COOLAPPV100" \
    -H "X-Parse-Session-Token: r:9805595b4a73c8d2135ae9e70bb885c6" \
    http://1.2.3.4/parse/classes/GameScore/LkTqWJKWw1

    # output
    {}
    ```

### Using the Master Key

**NOTE:** Oracle does not recommended using the master key to avoid ACLs.

Using the master key in an API call turns off all ACL checking. For example:

```
curl -X DELETE \
     -H "X-Parse-Application-Id: COOLAPPV100" \
     -H "X-Parse-Master-Key: MASTER_KEY" \
     http://1.2.3.4/parse/classes/GameScore/BLxUYqfh6E

# output:
{}
```

This call deletes the specified document regardless of any ACLs present.

Next, go to the [Sample Applications](../sample-apps/) page to learn how to use the Sample Applications.