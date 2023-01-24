---
title: "Friendly Eats tutorial"
---

This is an example of porting a simple Firebase web application based on [JavaScript Firebase API - version 8](https://firebase.google.com/docs/reference/js/v8)
and described in a public [Tutorial](https://firebase.google.com/codelabs/firestore-web#0) to the [Parse Platform](https://docs.parseplatform.org/js/guide/)
leveraging an alpha quality JavaScript library included in this example.

## Complete the original tutorial first

First, we recommend that you complete the original **FriendlyEats** tutorial [instructions](https://firebase.google.com/codelabs/firestore-web#0)
through to the end using Firebase.

## Adapt the code to use the Firebase API emulation

After completing the tutorial, you have a functioning application.  Next, you can adapt that application to use the developer preview
of the Firebase API emulation using the following steps:

* Open in a editor the file **index.html** in the directory **/friendlyeats**
* Look for the Firebase libraries imports:
    ``` 
    ...
    <script src="/__/firebase/9.6.6/firebase-app-compat.js"></script>
    <script src="/__/firebase/9.6.6/firebase-auth-compat.js"></script>
    <script src="/__/firebase/9.6.6/firebase-firestore-compat.js"></script>
    <script src="/__/firebase/init.js"></script>
    ...
    ```

    Comment out the Firebase imports and add the following imports and code in their place, as shown here.  Change the `COOLAPPV100`
    and `serverURL` to match your Oracle Backend for Parse Platform environment:
    
    ```
    <!-- comment these out: 
    <script src="/__/firebase/9.6.6/firebase-app-compat.js"></script>
    <script src="/__/firebase/9.6.6/firebase-auth-compat.js"></script>
    <script src="/__/firebase/9.6.6/firebase-firestore-compat.js"></script>
    <script src="/__/firebase/init.js"></script>
    -->
    <script src="//unpkg.com/navigo@6"></script>

    <!-- add this: -->
    <script src="/parsef/parsef.js"></script>
    <script src="https://npmcdn.com/parse/dist/parse.min.js"></script> 
    <script>
        firebase.app().options.appKey="COOLAPPV100";
        Parse.initialize(firebase.app().options.appKey);
        Parse.serverURL = "http://localhost:1337/parse";
    </script>
    ```
    
    The added lines do the following: 

    * The **Firebase API emulation** library (called "parsef") is included with this line:
        ```
        <script src="/parsef/parsef.js"></script>
        ```
        To enable the import, create a directory `parsef` under the project directory and copy the file
        [parsef.js](https://github.com/oracle/microservices-datadriven/blob/main/mbaas-developer-preview/parsef/parsef.js) into it.

    * The **Parse JavaScript SDK** is included by this line: 
        ```
        <script src="https://npmcdn.com/parse/dist/parse.min.js"></script> 
        ```

    * To configure communication with the Oracle Backend for Parse Platform, you must set your own **APPLICATION_ID** and **Parse serverURL**.
      This initial setup is done by these lines of code:
        ```
        <script>
            firebase.app().options.appKey="COOLAPPV100";
            Parse.initialize(firebase.app().options.appKey);
            Parse.serverURL = "http://localhost:1337/parse";
        </script>
        ```
    Change the code according to your actual Parse server URL and `COOLAPPV100`.

## Repeat the tutorial steps with Firebase API Emulation

Repeat the original tutorial steps to load **Restaurants** and **Ratings** into the Parse Server and check if the original
JavaScript demo application is still running without any other changes.

* Stop and restart the Firebase CLI.
* Reload the web page from **http://127.0.0.1:5000**

    ![Mock](../../mockRestaurants.jpg "mock restaurant data")

* Click on "ADD MOCK DATA" and wait until it finishes to add restaurants to Parse Server.

    ![Restaurant](../../restaurants.jpg "restaurant page")

* Click on any restaurant. Notice that ratings are empty because the client is no longer asking for data from Firebase/Firestore.

    ![MockRatings](../../mockRatings.jpg "mock ratings page")

* Click on "ADD MOCK RATINGS". In a few seconds, you should see the list of ratings added. If not, close the page by clicking **X** on left up
  corner, and click again on the same restaurant to force a reload: 


    ![Ratings](../../Ratings.jpg "ratings page")

* The **+** button on right up corner can be clicked on to add your own rating to the restaurant:

    ![addRatings](../../addRatings.jpg "add ratings page")

    Notice the list is updated after saving: 
    ![listAfterAdd](../../newRatings.jpg "list after add rating")

* Check the original sort and Filter functions. Choose "Ramen" as the "Category":
    ![Filter](../../filter.jpg "filter page")

    Notice the updated page after the filter is applied:
    
    ![Filtered](../../newList.jpg "filtered  restaurant page")
    
    **Note**: In this step, we don't need to add an index definition to the collection as in the original tutorial, since this is done
    automatically in the Parse Server.

* You can further test the sort functionalities by adding more reviews to other restaurants. This will allow you to see the number of reviews and average ratings.

