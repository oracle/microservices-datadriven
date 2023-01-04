
The *Walking History* sample application uses the Parse database and GeoPoints APIs.  It is a React Native application
that allows you to walk around New York City (or simulate that in a device emulator) and it will tell you about the
closest attraction or "point of interest."

Here is what the Walking History app looks like running in the Android emulator:

![Walking History](../../mbaas-walking-history.png)

## Try the sample

To try this sample application you will need the following: 

- An instance of Oracle Mobile Backend as a Service deployed and running.
- Android Studio or XCode, with the device emulator.
  For Android, use API level 30 and Android 11 for compatibilty with the version of React Native used in the sample.
- NodeJS to run the React Native "metro" development server. 

Once you have the prerequisites, start by cloning the source code for the application:

```
git clone https://github.com/oracle/microservices-datadriven
cd microservices-datadriven/mbaas-developer-preview/walking-history
```

This directory contains the source code for the application.    

In the source code, you need to update the file `App.js` to set the APPLICAITON_ID and server URL to match your environment.
Find these lines and update those two values.  Note that the required values were provided in the output at the end of
the log for the stack apply job during the installation.

```
const App: () => Node = () => {
  const isDarkMode = useColorScheme() === 'dark';

  const Parse = require('parse/react-native.js');
  Parse.setAsyncStorage(AsyncStorage);
  Parse.initialize("APPLICATION_ID");         //   <-- update this
  Parse.serverURL = 'http://1.2.3.4/parse';   //   <-- update this
```

Once you have made the updates, you can start the "metro" development server by running this command:

```
npx react-native start
```

**Note:** The instructions below are for Android.  If you are using iOS, do the equivalent steps in XCode.

Open the `android` sub-directory as a project in Android Studio.  Create an emulator if you have not already (noting the
specific version requirements above) and then click on the "Run" button (or choose "Run..." from the "Run" menu) to start
the application on the emulator.

Click on the "..." item in the emulator menu to open the "Extended Controls."  In the "Location" page create a new
route from 33 Peck Slip, New York to 14 W 34th Street, New York.  Set the playplack speed to 4x and click on the
"Play Route" button.  Your emulator will now silumate walking around New York City for several minutes. 

As you "walk" around, you will see the application updates your location and the nearest point of interest
will change.

### Explore the Parse API usage in the source code

In addition to the Parse initialization in `App.js` you saw above, you may wish to review the file
`components\Location.js` which uses the Parse Query API and the GeoPoints API to find a list of points of
interest that are near the current location of the device (emulator):

```
// find the closest attraction and update the state
console.log("querying parse server for nearby attractions");
let query = new Parse.Query('POI');
query.near('location', new Parse.GeoPoint(currentPosition.coords.latitude,
    currentPosition.coords.longitude));
let results = await query.find().catch(err => console.log("OOPS " + JSON.stringify(err)));
```
