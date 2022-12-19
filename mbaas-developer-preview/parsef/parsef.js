// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

//based on firebase JS SDK v.8 
const DEBUG = false;

class CollectionReference {
    firestore = null;
    id = "";
    path = "";
    parent = null;

    //app = ""; // APPLICATION_ID
    _query = null;
    #coll = null;

    constructor(){
        this.app = firebase.app().options.appKey;
        console.log("CollectionReference Constructor : App:"+this.app);
    }
    init(){
        Parse.initialize(firebase.app().options.appKey);
        this.#coll = Parse.Object.extend(this.id);
        this._query = new Parse.Query(this.#coll);
        const pathStrSplit= this.path.split("/");
        if (pathStrSplit.length > 2)  {  
            //NOT ROOT DOCUMENT
            const parentID =pathStrSplit[pathStrSplit.length-2];
            this._query.equalTo("parent__",parentID);
        }
    }
    add(data) {
        let doc = new this.#coll();
        const pathStrSplit= this.path.split("/");
        data.parent__=((pathStrSplit.length > 2)  ?  pathStrSplit[pathStrSplit.length-2] : '');
        data.path__=this.path;
        return doc.save(data);
    }

    orderBy(fieldPath, directionStr){
        if (DEBUG) {
        let actualFieldPath = fieldPath;
        if (fieldPath=='timestamp'){
            actualFieldPath = 'updatedAt'
        }
        if (directionStr == 'desc') { this._query.descending(actualFieldPath);}
            else {
                if (directionStr == 'asc') { this._query.ascending(actualFieldPath);}
            } 
        }
        //return(this);
        let qs = new Query();
        qs._query=this._query;
        return qs;
    }

    limit(limit){
        this._query.limit(limit);
        //return(this);
        let qs = new Query();
        qs._query=this._query;
        return qs;

    }

    async onSnapshot(observer){

        const querySnapshot = await this._query.find(); 
        querySnapshot.size=querySnapshot.length;
        console.log("querySnapshot.size in _onSnapshot");
        console.log(querySnapshot.size);
        querySnapshot.empty=false;
        if (querySnapshot.size == 0){ querySnapshot.empty=true; }
        console.log("querySnapshot.empty");
        console.log(querySnapshot.empty);

        querySnapshot.docChanges = () => {
            querySnapshot.forEach(
                function(obj){
                    obj.type='added';
                    let temp = JSON.parse(JSON.stringify(obj));
                    temp.id = obj.id;
                    temp.data = () => { return temp; }
                    obj.doc = temp; 
                }
            );
            return querySnapshot;
        };
        return observer(querySnapshot);
    }

    doc (documentPath){
        //IF documentPath -> save the Object on Parse in DocumentReference() and get ObjectID
       let _DocumentReference= new DocumentReference();
       _DocumentReference.id=documentPath;
       if (this.parent != null){
           if (this.parent.path != '') {
                _DocumentReference.path=this.parent.path+'/'+this.id+'/'+documentPath;
               } }
       else {
        _DocumentReference.path=this.id+'/'+documentPath; //LAST was: this.id+'/'+documentPath
       }
       return _DocumentReference;
    }

    get(){
        // ******
        // implement the return of a Promise of QuerySnapshot
        const querySnapshot = this._query.find().then((results)=>{
            const qs=new QuerySnapshot();
            qs.docs= new Array();
            for (let i = 0; i < results.length; i++) {
                const obj = results[i];
                const queryDocumentSnapshot = new QueryDocumentSnapshot();
                queryDocumentSnapshot.id = obj.id;
                queryDocumentSnapshot._data= JSON.parse(JSON.stringify(obj));
                qs.docs.push(queryDocumentSnapshot);
              }
            qs.empty= (results.length==0) ? true : false;
            qs.size=results.length;
            qs.query = null ; //TO BE IMPLEMENTED. Must return a Query object type
            return qs;
        })
        .catch(function(error) {
            // There was an error.
            const qs=new QuerySnapshot();
            qs.docs= new Array();
            qs.empty=true;
            qs.size=0;
            console.log("error in CollectionReference.get()");
            return(qs);
          });
        ;
        // ******
        const myPromise = new Promise((resolve, reject) => {
            setTimeout(() => {resolve(querySnapshot);reject(querySnapshot);}, 1);
        });
    return myPromise;

    }

    where (fieldPath,opStr,value){
        let query= new Query();
        query._query= this._query;
        /*
        if (opStr == '=='){
            query._query.equalTo(fieldPath,value)
        }
        */
        query._query=_query(query._query,fieldPath,opStr,value);
        return query;
    }


}

class Query {
    _query=null;

    constructor (){
        console.log("Query : Constructor");
    }
    
    where (fieldPath,opStr,value){
        //let query= new Query();
        //query._query= this._query;
        /*
        if (opStr == '=='){
            query._query.equalTo(fieldPath,value)
        }
        */
        //query._query=_query(this._query,fieldPath,opStr,value);
        this._query = _query(this._query,fieldPath,opStr,value);
        return this;
    }

    orderBy(fieldPath, directionStr){
        if (DEBUG){
        let actualFieldPath = fieldPath;
        if (fieldPath=='timestamp'){
            actualFieldPath = 'updatedAt'
        }
        if (directionStr == 'desc') { this._query.descending(actualFieldPath);}
            else {
                if (directionStr == 'asc') { this._query.ascending(actualFieldPath);}
            } 
        }
        return(this);
    }

    limit(limit){
        this._query.limit(limit);
        return(this);
    }

    get(){
        // ******
        // implement the return of a Promise of QuerySnapshot
        const querySnapshot = this._query.find().then((results)=>{
            const qs=new QuerySnapshot();
            qs.docs= new Array();
            for (let i = 0; i < results.length; i++) {
                const obj = results[i];
                const queryDocumentSnapshot = new QueryDocumentSnapshot();
                queryDocumentSnapshot.id = obj.id;
                queryDocumentSnapshot._data= JSON.parse(JSON.stringify(obj));
                qs.docs.push(queryDocumentSnapshot);
              }
            qs.empty= (results.length==0) ? true : false;
            qs.size=results.length;
            qs.query = null ; //TO BE IMPLEMENTED. Must return a Query object type
            return qs;
        })
        .catch(function(error) {
            // There was an error.
            const qs=new QuerySnapshot();
            qs.docs= new Array();
            qs.empty=true;
            qs.size=0;
            console.log("error in CollectionReference.get()");
            return(qs);
          });
        ;
        // ******
        const myPromise = new Promise((resolve, reject) => {
            setTimeout(() => {resolve(querySnapshot);reject(querySnapshot);}, 1);
        });
    return myPromise;

    }


    async onSnapshot(observer){

        const querySnapshot = await this._query.find(); 
        querySnapshot.size=querySnapshot.length;
        console.log("querySnapshot.size in _onSnapshot");
        console.log(querySnapshot.size);
        querySnapshot.empty=false;
        if (querySnapshot.size == 0){ querySnapshot.empty=true; }
        console.log("querySnapshot.empty");
        console.log(querySnapshot.empty);

        querySnapshot.docChanges = () => {
            querySnapshot.forEach(
                function(obj){
                    obj.type='added';
                    let temp = JSON.parse(JSON.stringify(obj));
                    temp.id = obj.id;
                    temp.data = () => { return temp; }
                    obj.doc = temp; 
                }
            );
            return querySnapshot;
        };
        return observer(querySnapshot);
    }
}

class QueryDocumentSnapshot {
    metadata = null;
    exists = true;
    id = null;
    ref = null;
    _data = { };

    constructor (){
        console.log("QueryDocumentSnapshot created");
    }
    data (options) {
        console.log(this._data);
        return (this._data._data);
    } 
    get (fieldPath,options){
        return (this._data[fieldPath]);
    }

    //TO BE IMPLEMENTED
    isEqual(other ) {
        return false;
    }
}

class DocumentReference {
    firestore="";
    id="";
    path="";
    parent="";
    constructor (){
        console.log("Document Reference Constructor");
    }

    get(options){
        const pathStrSplit= this.path.split("/");
        const collectionName =pathStrSplit[pathStrSplit.length-2];
        const Collection = Parse.Object.extend(collectionName);
        const query = new Parse.Query(Collection);
        const t = query.get(this.id).then( (obj)=>{
                    let temp = new DocumentSnapshot();
                    temp._data=JSON.parse(JSON.stringify(obj));
                    temp.id = obj.id;
                    temp.exists=true;
                    temp.ref = new DocumentReference();
                    temp.ref.id=obj.id;
                    temp.ref.path=obj.className+"/"+obj.id;
                    temp.ref.parent={ 
                        id : obj.className,
                        parent : null,
                        path : obj.className
                    };
                    
                    return temp;
                }
            );
        const myPromise = new Promise((resolve, reject) => {
                setTimeout(() => {resolve(t);}, 1);
            });
        return myPromise;
    }  

    collection(collectionPath){
        let _CollectionReference = new CollectionReference();
        _CollectionReference.id = collectionPath;
        _CollectionReference.path= this.path+"/"+collectionPath;
        _CollectionReference.firestore = null;
        _CollectionReference.parent=this;
        _CollectionReference.init();
        return _CollectionReference;
    }
}

class QuerySnapshot {
    docs =[]; 
    empty;
    metadata = {};
    query = null;
    size = 0;

    forEach(callback,thisArg) {
        this.docs.forEach(doc => {
            let queryDocumentSnapshot = new QueryDocumentSnapshot();
            queryDocumentSnapshot.metadata = null; //TO BE IMPLEMENTED
            queryDocumentSnapshot.exists = true;
            queryDocumentSnapshot.ref = null; 
            queryDocumentSnapshot.id = doc.id;
            queryDocumentSnapshot._data= JSON.parse(JSON.stringify(doc));
            callback(queryDocumentSnapshot);
        });
    }

}

class DocumentSnapshot{
    exists=false;
    id="";
    ref=null;
    metadata={};
    _data={};
    constructor (){
        console.log("DocumentSnapshot Constructor");
        this.ref= new DocumentReference();
    }

    data(options){
        console.log("Data()");
        return (this._data);
    }
}

class Firestore {
    app = '';

    constructor (app) {
        console.log("Firestore Constructor:");
        if (typeof(app) === 'undefined') { 
            this.app = firebase.app().options.appKey;
        } else { 
            firebase.app().options.appKey=app; 
            this.app;
        }
        
    }

    collection (name){
        let _CollectionReference = new CollectionReference();
        _CollectionReference.id = name;
        _CollectionReference.init();
        return _CollectionReference;
    }

    runTransaction(func){
        let transaction = new Transaction();
        return func(transaction);
    }

}
// NOT YET ACTUALLY TRANSACTIONAL
class Transaction {
    tx = null;
    _numAttempts = 0;
    _MAX_ATTEMPTS = 10;
    _app = firebase.app().options.appKey;
    constructor(){
        console.log("Transaction constructor");
        let length = 5;
        var result           = '';
        var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        var charactersLength = characters.length;
        for ( var i = 0; i < length; i++ ) {
                result += characters.charAt(Math.floor(Math.random() * charactersLength));
            }
        this.tx=result;
        console.log("Transaction.Constructor() tx:"+this.tx);
    }

    delete(){

    }

    get (documentRef) {
        console.log("Transaction.get() tx:"+this.tx);
        const pathStrSplit= documentRef.path.split("/");
        const collectionName =pathStrSplit[pathStrSplit.length-2];
        const id = documentRef.id;
        const CollectionToGet = Parse.Object.extend(collectionName);
        const query = new Parse.Query(CollectionToGet);
        return query.get(id).then((doc)=>{
                    return doc.fetch();
                    }).then((docFtc)=>{
                        if ((docFtc.get('tx_')==null )||(this._numAttempts>this._MAX_ATTEMPTS)){
                            this._numAttempts=0;
                            docFtc.set('tx_',this.tx)
                            console.log("Transaction.get() -> after fetch");
                            console.log("_setObj() objectId:"+docFtc.id);
                                return docFtc.save().then((docSaved)=>{
                                    const documentSnapshot = new DocumentSnapshot();
                                    documentSnapshot.id=documentRef.id;
                                    documentSnapshot.path=documentRef.path;
                                    documentSnapshot._data= JSON.parse(JSON.stringify(docSaved));
                                    return documentSnapshot;
                                });
                        } else {
                            this._numAttempts=this._numAttempts+1;
                            console.log("Transaction.get() -> after fetch tx_ NOT NULL");
                            return this.get(documentRef);
                    } 
                });
    }
    
    set (documentRef, data,options) {
        if (typeof(documentRef.id ) === 'undefined'){

            const pathStrSplit= documentRef.path.split("/");
            const collectionName =pathStrSplit[pathStrSplit.length-2];
            const Collection = Parse.Object.extend(collectionName);
            data.path__=documentRef.path;
            data.parent__=((pathStrSplit.length > 2)  ?  pathStrSplit[pathStrSplit.length-3] : '')
            const collection= new Collection();
            collection.save(data).then((doc) => {
              // The object was saved successfully.
              console.log(doc);
              documentRef.id=doc.id;
              documentRef.path=documentRef.path+'/'+doc.id;
              console.log("Transaction.set() tx:"+this.tx);
            }, (error) => {
              // The save failed.
              console.log("Transaction.set() Error");
            });
        } else {
            //TO IMPLEMENT
            console.log("Transaction.set(): Existing Object, TO BE IMPLEMENTED");
        }
        return this;

    }

    update(documentRef,data) {

        const pathStrSplit= documentRef.path.split("/");
        const collectionName =pathStrSplit[pathStrSplit.length-2];
        const Collection = Parse.Object.extend(collectionName);
        const query = new Parse.Query(Collection);
        query.get(documentRef.id).then(
            (obj)=>{
                const props=Object.keys(data);
                props.forEach((x,i)=> { obj.set(x,data[x]); });
                obj.set('tx_',null);
                //console.log("Transaction.Update(): get object "+documentRef.id);
                obj.save();
                console.log("Transaction.Update(): saved object "+documentRef.id);
                console.log("Transaction.Update() tx closed:"+this.tx);
                console.log("Transaction.Update() Num. Ratings:"+obj.get('numRatings'));
            },
            (error)=>{console.log("error in Transaction.Update()"); }
        );
        
        return this;
    }
}



function initializeFirestore(app,settings,databaseId){
    return new Firestore(app);
}

const _auth = {
    currentUser : { uid: "Bob"},
    signInAnonymously: function() {
        let auth = new Promise(function (resolve, reject) {
            resolve("Authentication done resolved");
        });
        return auth;
    }
}

const firebase = {
    firestore (){
        return new Firestore();
    }, 
    auth() {
            return _auth;
        },
    app() {
        return FirebaseAppSettings;
        }
    }
 
var FirebaseAppSettings = {
  options : {
        appKey : "",
        authDomanin : "",
        messagingSenderId:"",
        projectId:"",
        storageBucket:"",

    }
}

const WhereFilterOp= new Set(["<","<=","==","!=",">=",">","array-contains","in","array-contains-any","not-in"]);
function _query(q,fieldPath,opStr,value){
    switch(opStr){
        case "<" : q.equalTo(fieldPath,value); break;
        case "<=": q.lessThanOrEqualTo(fieldPath,value); break;
        case "==": q.equalTo(fieldPath,value); break;
        case "!=": q.notEqualTo(fieldPath,value); break;
        case ">=": q.greaterThanOrEqualTo(fieldPath,value);break;
        case ">" : q.greaterThan(fieldPath,value);break;
        case "array-contains": q.containedIn(fieldPath,value);break; //TBV
        case "in":q.contains(fieldPath,value);break; //TBV
        case "array-contains-any":q.containsAll(fieldPath,value);break; //TBV
        case "not-in":q.notContainedIn(fieldPath,value);break; //TBV
        default:
    }
    return q;
}
