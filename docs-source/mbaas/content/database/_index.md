---
title: "Database Access"
---

# Database Access

The Oracle Backend for Parse Platform includes an Oracle Database storage adapter for Parse which allows the Parse Server to use the Oracle database.
An instance of Oracle Autonomous Database Serverless is created during installation of the Oracle Backend for Parse Platform.

To work with data in the database, you can use the **Database Actions** interface, which can be accessed from the OCI Console.
The Oracle database is created in the same compartments as the Parse Server. In the OCI Console, navigate to Autonomous Database in the main menu
and select the database with the application name that you configured during installation with the suffix `DB`. For example `COOLAPPDB`.

![COOLAPPDB](../mbaas-coolappdb.png)

Click on the link to access the database details page, and then click **Database Actions**. For example:

![COOLAPPDB](../mbaas-coolappdb-details.png)

This opens the **Database Actions** page where you have access to many database functions, including the ability to
work with the JavaScript Object Notation (JSON) collections where your Oracle Backend for Parse Platform data is stored.

**NOTE:** If you are asked for credentials, you can obtain them by [connecting to the Kubernetes cluster](../cluster-access) and extracting the password
from the Parse Server log using the following command. You need to use the correct name of the Pod on your system, which is different than the name used in this
example. In the following example, the user name is `adam` and the password is `apple`.  You can use these credentials to log into **Database Actions**.

```
user@cloudshell:~ (us-ashburn-1)$ kubectl logs parse-server-646b97979-9pkq6 -n parse-server | grep databaseURI
databaseURI: oracledb://adam:apple@MYMBAASAPPDB_TP
```

![Database Actions](../mbaas-database-actions.png)

Select the JSON tile to access the JSON Console.

At startup, the Parse Server creates a few collections including `_Hooks`, `_SCHEMA` and `_User`.  The `_SCHEMA` collection is where
the schema of other collections are defined. For example:

![The _SCHEMA collection](../mbaas-schema-collection.png)

Two schema entries are created in this collection during the server boot, called `_User` and `_Role` as you can see in the preceding image.

The `GameScore` schema would have been created when you made the first `POST` request in the **Working with Objects** page.
You can see the contents of the `GameScore` collection in the JSON database. For example:

![GameScore collection](../mbaas-gamescore.png)

Next, go to the [Kubernetes Access](../cluster-access/) page to learn about Kubernetes access.
