---
title: "Database Access"
---


The MBaaS includes an *Oracle Database storage adapter for Parse* which allows Parse Server to use the Oracle Database.
An instance of the Oracle Autonomous Database (Shared) is created during installation of the MBaaS.

To work with data in the database, you can use the Database Actions interface, which can be accessed from the OCI Console.
The Oracle Database is created in the same compartments as Parse Server.  In the OCI Console, navigate to Autonomous Database in the main menu
and select the database with the Application Name you configured during install, with the suffix "DB", for example "COOLAPPDB".

![COOLAPPDB](../mbaas-coolappdb.png)

Click on the link to access the database details page, and then click on the "Database Actions" button:

![COOLAPPDB](../mbaas-coolappdb-details.png)

This will open the Database Actions page, where you have access to many database functions, including the ability to
work with the JSON Collections where your MBaaS data are stored.

![Database Actions](../mbaas-database-actions.png)

Select the JSON tile to enter the JSON Console.

At startup, Parse Server creates a few collections including `_Hooks`, `_SCHEMA` and `_User`.  The `_SCHEMA` collection is where
the schema of other collections are defined.

![The _SCHEMA collection](../mbaas-schema-collection.png)

Two schema entries are created in this collection during server boot, for `_User` and `_Role` as you can see in the image above.

The `GameScore` schema would have been created when you made the first POST request in the "Working with Objects" page.
You can see the contents of the `GameScore` collection in the JSON database: 

![GameScore collection](../mbaas-gamescore.png)


