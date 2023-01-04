#!/bin/bash
# for c in my-parse-server my-mongo; do 

node <<EOF
    const Parse = require('parse/node');

    Parse.initialize("YOUR_APPLICATION_ID");
    Parse.serverURL = 'http://1.2.3.4/parse';

    async function loadPOI(name, location, image, audio) {
        let POI = new Parse.Object("POI");
        POI.set('name', name);
        POI.set('location', location);
        POI.set('image', image);
        POI.set('audio', audio);
        await POI.save();
        console.log(name);
    }

    console.log('creating users...');
    async function createUsers() {
        const user = new Parse.User();
        user.set("username", "mark");
        user.set("password", "welcome1");
        user.set("email", "somebody@example.com");
        await user.signUp();
    }
    createUsers();

    console.log('loading point of interest...');
    loadPOI(
        'Brooklyn Bridge', 
        new Parse.GeoPoint(40.7061, -73.9969), 
        'https://objectstorage.us-ashburn-1.oraclecloud.com/n/maacloud/b/mbaas/o/images%2FBrooklyn_Bridge_Manhattan.jpg', 
        'https://objectstorage.us-ashburn-1.oraclecloud.com/n/maacloud/b/mbaas/o/mp3%2Fbrooklyn-bridge.mp3'
    );
    loadPOI(
        'Empire State Building', 
        new Parse.GeoPoint(40.7486, -73.9857),
        'https://objectstorage.us-ashburn-1.oraclecloud.com/n/maacloud/b/mbaas/o/images%2Fempire-state-building.jpg',
        'https://objectstorage.us-ashburn-1.oraclecloud.com/n/maacloud/b/mbaas/o/mp3%2Fempire-state-building.mp3'
    );
    loadPOI(
        'Union Square', 
        new Parse.GeoPoint(40.7358, -73.9905),
        'https://objectstorage.us-ashburn-1.oraclecloud.com/n/maacloud/b/mbaas/o/images%2Funion-square.jpg',
        ''
    );
    loadPOI(
        'Flatiron Building', 
        new Parse.GeoPoint(40.7411, -73.9897),
        'https://objectstorage.us-ashburn-1.oraclecloud.com/n/maacloud/b/mbaas/o/images%2Fflatiron.jpg',
        ''
    );
    loadPOI(
        'Flatiron Building', 
        new Parse.GeoPoint(40.7411, -73.9897),
        'https://objectstorage.us-ashburn-1.oraclecloud.com/n/maacloud/b/mbaas/o/images%2Fflatiron.jpg',
        ''
    );
    loadPOI(
        'Jacob K. Javits Federal Building', 
        new Parse.GeoPoint(40.7155, -74.0042),
        'https://objectstorage.us-ashburn-1.oraclecloud.com/n/maacloud/b/mbaas/o/images%2Fjavits.jpg',
        ''
    );
    loadPOI(
        'New York City Hall', 
        new Parse.GeoPoint(40.7128, -74.0061),
        'https://objectstorage.us-ashburn-1.oraclecloud.com/n/maacloud/b/mbaas/o/images%2Fcity-hall.jpg',
        ''
    );
    
    console.log('done');
EOF
