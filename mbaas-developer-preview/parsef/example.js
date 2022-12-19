// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

// Get Restaurants
async function getRestaurants() {

    const Restaurants = Parse.Object.extend("restaurants"); 
    const q = new Parse.Query(Restaurants);
    q.equalTo('name','Vesuvius');
    const querySnapshot = await q.find(); 

    if (querySnapshot.length>0) { 
        const doc = querySnapshot[0]; 
        console.log( 
            doc.id + ' => ' + JSON.stringify(doc)        
        ); 
        alert(
        `GET: ${
          doc.id
        }, ${JSON.stringify(doc)}`
      );

    } else {alert("Empty!")};
  }

async function insertRestaurants() {

  var Restaurants = Parse.Object.extend("restaurants");
  var category = "Mediterranean";
  var name = "Vesuvius";

  restaurants = new Restaurants();
  const doc = {name:name,category:category};
  const result = await restaurants.save(doc).then(function(res){
      alert( `ObjectId:  ${JSON.stringify(res)}`);
      console.log(res);
  }).catch(function(error){
     console.log('Error: ' + error.message);
  });
  console.log(result);   
  }

async function updateRestaurants(){

const Restaurants = Parse.Object.extend("restaurants");
  const query = new Parse.Query(Restaurants);
  query.equalTo('name','Vesuvius');
  await query.find().then(function (results) {
    let qux=results[0];
    console.log(results);
    qux.set('city', 'Naples');
    Parse.Object.saveAll([qux]).then(()=>{
      alert(`Updated!`);});
      console.log('Updated!');
  });
}

async function getAllRestaurants() {
  var query = firebase.firestore()
  .collection('restaurants')
  .orderBy('avgRating', 'desc')
  .limit(50);
  console.log(query);
  query.onSnapshot(function(snapshot) {  
    alert(`restaurants collection size: ${snapshot.size}`);
  });
};


// Add on click listener to call the create parse user function
document.getElementById("createButton").addEventListener("click", async function () {
  getRestaurants() ;
});

// Add on click listener to call the create parse user function
document.getElementById("insertButton").addEventListener("click", async function () {
  insertRestaurants() ;
});

// Add on click listener to call the create parse user function
document.getElementById("updateButton").addEventListener("click", async function () {
  updateRestaurants() ;
});

// Add on click listener to call the create parse user function
document.getElementById("queryButton").addEventListener("click", async function () {
    getAllRestaurants() ;
  });