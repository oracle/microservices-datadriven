---
title: "Firebase API Emulation"
---

The developer preview includes an example of Firebase API emulation.

The Firebase API emulation is implemented in a library called `parsef`. This library is **alpha quality** and provided
only as a proof of concept for developers to experiment with.

This is an example of porting a simple Firebase web application based on [JavaScript Firebase API - version 8](https://firebase.google.com/docs/reference/js/v8)
and described in a public [Tutorial](https://firebase.google.com/codelabs/firestore-web#0) to the [Parse Platform](https://docs.parseplatform.org/js/guide/)
leveraging an alpha quality Javascript library included in this example.

## Setup instructions

* Execute the original **FriendlyEats** lab [instructions](https://firebase.google.com/codelabs/firestore-web#0) up to the end.
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
    Comment out the Firebase imports and add the following imports and code in their place, as shown here.  Change the `APPLICATION_ID`
    and `serverURL` to match your MBaaS/Parse Server environment:
    ```
    <!--
    <script src="/__/firebase/9.6.6/firebase-app-compat.js"></script>
    <script src="/__/firebase/9.6.6/firebase-auth-compat.js"></script>
    <script src="/__/firebase/9.6.6/firebase-firestore-compat.js"></script>
    <script src="/__/firebase/init.js"></script>
    -->
    <script src="//unpkg.com/navigo@6"></script>

    <script src="/parsef/parsef.js"></script>
    <script src="https://npmcdn.com/parse/dist/parse.min.js"></script> 
    <script>
        firebase.app().options.appKey="APPLICATION_ID";
        Parse.initialize(firebase.app().options.appKey);
        Parse.serverURL = "http://localhost:1337/parse";
    </script>
    ```
* Let's explain the lines added: 
    * The **Firebase-on-Parse APIs** are included with:
        ```
        <script src="/parsef/parsef.js"></script>
        ```
        To enable the import, create a directory "parsef" under [HOME] project dir and put it in the file [parsef.js](parsef.js) .
    * **Parse JavaScript SDK** is included through: 
        ```
        <script src="https://npmcdn.com/parse/dist/parse.min.js"></script> 
        ```
    * To allow the communication with Parse Platform, you should set your own **APPLICATION_ID** and **Parse serverURL**. This initial setup is done by these lines of code:
        ```
        <script>
            firebase.app().options.appKey="APPLICATION_ID";
            Parse.initialize(firebase.app().options.appKey);
            Parse.serverURL = "http://localhost:1337/parse";
        </script>
        ```
    Change the code according to your actual Parse server URL and APPLICATION_ID.

* Now let's go over the original tutorial steps to load **Restaurants** and **Ratings** in Parse Server and check if the original Javascript demo application it's still running without any other changes.
* Stop and restart the Firebase CLI.
* Reload the web page from **http://127.0.0.1:5000**

    ![Mock](img/mockRestaurants.jpg "mock restaurant data")
* Click on "ADD MOCK DATA" and wait until it finishes to add restaurants to Parse Server.

    ![Restaurant](img/restaurants.jpg "restaurant page")
* Click on one restaurants. You can notice that ratings are empty because client is no more asking for data from Firebase/Firestore.

    ![MockRatings](img/mockRatings.jpg "mock ratings page")

* Click on "ADD MOCK RATINGS". If you should see in a few seconds the list of ratings added. If not, close the page  by clicking **X** on left up corner, and click again on the same restaurant: 


    ![Ratings](img/Ratings.jpg "ratings page")

* The **+** button on right up corner is also operating. Click on it and add your own rating to the restaurant:

    ![addRatings](img/addRatings.jpg "add ratings page")

    and watch the list updated after saving: 
    ![listAfterAdd](img/newRatings.jpg "list after add rating")

* Now let's check the original Sort and Filter functionalities. Choosing "Ramen" as "Category" type to see in this case shown only the "Fire Prime" restaurants:
    ![Filter](img/filter.jpg "filter page")
page after filter applied:
    ![Filtered](img/newList.jpg "filtered  restaurant page")
NOTE: in this step, we don't need to add an index definition to Collections created as in the original demo.

* Adding more reviews to other restaurants you could also test the Sort functionalities, for a number of reviews or average ratings.

## Additional Parse test code
To test the Parse API direct access from the same page, let's add a few lines of codes to the **index.html** to show four buttons to insert/get/update a Restaurant (minimum properties) in the same collection created from Firebase-on-Parse SDK. The application logic is in [**/parsef/example.js**](./example.js) file.

* The modified parts included in **index.html** become:

    ```
    <!--ORACLE-->
    <div style="text-align: center">
    <p>
    <button id="insertButton">INSERT RESTAURANT</button><p>
    <button id="createButton">GET RESTAURANT</button><p>
    <button id="updateButton">SET RESTAURANT</button><p>
    <button id="queryButton" >N° RESTAURANTS</button>
    </div>
    </pre>
    <!--
    <script src="/__/firebase/9.6.6/firebase-app-compat.js"></script>
    <script src="/__/firebase/9.6.6/firebase-auth-compat.js"></script>
    <script src="/__/firebase/9.6.6/firebase-firestore-compat.js"></script> 
    <script src="/__/firebase/init.js"></script>
    -->
    <!--ORACLE-->
    <script src="//unpkg.com/navigo@6"></script>

    <!--ORACLE  -->
    <script src="/parsef/parsef.js"></script>
    <script src="https://npmcdn.com/parse/dist/parse.min.js"></script> 
    <script>
    firebase.app().options.appKey="APPLICATION_ID";
    Parse.initialize(firebase.app().options.appKey);
    Parse.serverURL = "http://localhost:1337/parse";
    </script>
    <script src="/parsef/example.js"></script>
    <!-- ORACLE-->
    ```
* Reloading the page should appear four new buttons. Behind these buttons there are Parse JS API calls for **Insert/Get/Update**, and still Firebase API to count how many restaurants are in the Parse database:

    ![Filter](img/buttons.jpg "filter page")
* Click in sequence:
    * Insert Restaurant: 

        ![Insert](img/insert.jpg "insert")

    * Get Restaurant (Note: only Name and Category have been added):

        ![Get](img/get.jpg "get")

    * Set Restaurant:

        ![Set](img/set.jpg "set")

    * Get Restaurant (Note: that the additional field city has been added):

       ![Updated](img/updated.jpg "updated")

* If you click on **N° Restaurants** you will get the **size** of restaurants based on a Firebase API calls.



