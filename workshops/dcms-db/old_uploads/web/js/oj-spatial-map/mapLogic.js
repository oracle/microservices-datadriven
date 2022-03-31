/*
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
define([
    'jquery',
    './lib/mapbox-gl/mapbox-gl',
    'text!./map-styles/oracle_world_map.json',
    'text!./map-styles/oracle_osm_bright.json',
    'text!./map-styles/oracle_osm_positron.json',
    'text!./map-styles/oracle_osm_darkmatter.json',
    'css!./lib/mapbox-gl/mapbox-gl.css'    
],

function($, 
    mapboxgl, 
    oracle_world_map_json, 
    oracle_osm_bright_json, 
    oracle_osm_positron_json, 
    oracle_osm_darkmatter_json)
{

    /**
     * The class that handles all aspects of a geographic map.
     * 
     * @param {Object} config configuration containing various map related properties.  It must
     *                        contain an 'element' property whose values is a DIV element serving as
     *                        the map display container.
     */
    function MapLogic (config){

        if(!config || !config.element){
            throw 'Invalid configuration found.';
        }

        var styleStr = _setMapStyleBaseUrl(oracle_world_map_json);
        this.defaultMapStyle = JSON.parse(styleStr);
        styleStr = _setMapStyleBaseUrl(oracle_osm_bright_json);
        this.osmBrightMapStyle = JSON.parse(styleStr);
        styleStr = _setMapStyleBaseUrl(oracle_osm_positron_json);
        this.osmPositronMapStyle = JSON.parse(styleStr);
        styleStr = _setMapStyleBaseUrl(oracle_osm_darkmatter_json);
        this.osmDarkmatterMapStyle = JSON.parse(styleStr);

        // the current basemap style being used.
        this.currentMapStyle = null;

        // this variable holds the Mapbox Map instance.
        this.mapObject = null;
        this.mapObjectReadyPromise = null;

        // keep the initial map zoom and center as the map's "home" position.
        this.initZoom = 0;
        this.initLon = 122.5;
        this.initLat = 37.5;

        this.element = config.element;

        // keep track of the Web component's properties map. Passed in from the component's view model.
        this.componentProperties = null;

        // Internal cache of existing dataset objects. This is an array of the dataset objects passed in
        // by the application. Note that the order of the elements in the array determines the rendering order of
        // the datasets on the map.
        // TODO: find a more efficient way of caching an application dataset.        
        this.existingDatasets = [];

        this.nextImageIndex = 1;

    }

    // all the json files represent map styles has a place holder token "{BASE_URL}" in its
    // reference to the map sprites and fonts folder. This needs to be replaced by the real
    // base url at run time.
    function _setMapStyleBaseUrl(styleStr){

        //DRM - this bit needed to be tweaked to work correctly with requireJS given that 
        //      we may be referencing the component from many different locations including the CDN
        //      
        // We get the current location based on the requireJS path mapping which we know will be correct
        // but which may or may not be a full URL depending on the source of the component

        const requirePathForComponent =  require.toUrl('oj-spatial-map');
        const fullAddressMatch = RegExp('^(http[s]?:\/\/)','i');
        let baseUrl;
        
        if (fullAddressMatch.test(requirePathForComponent)) {
            baseUrl = requirePathForComponent;
        }
        else{
            //TODO remove this dependency on JQuery
            const protocol = $(location).attr('protocol');
            baseUrl = protocol + '//' + $(location).attr('host') + '/' + requirePathForComponent;
        }


        //Note I had to do a slight tweak to the JSON files as well 
        var str = styleStr.replace('{BASE_URL}', baseUrl);
        return str.replace('{BASE_URL}', baseUrl);
    }

    /**
     * Creates and intializes the underlying mapbox-gl-js Map object.
     * Returns a promise that is resolved once the Map object fully initializes.
     * The promise is to be kept in this.mapObjectReadyPromise.
     *
     * @param {Object} options  The map options such as initial zoom level and center point.
     *                          Here are some of the options and their default values.
     * 
     *     initZoom :  The map's initial zoom level; 0 if not specified.
     *     initLon :   The longitude of the map's initial center
     *     initLat :   The latitude of the map's initial center
     *     element :   The DIV element to display the map contents in
     *     basemap :   the basemap to display datasets on.
     */
    MapLogic.prototype.initializeMap = function(options) {
        const self = this;

        //do nothing if map is already initialized or being initialized.
        if (self.mapObjectReadyPromise) {
            return self.mapObjectReadyPromise;
        }

        if(!options){
            throw 'Invalid map initialization options';
        }

        // Almost all actions on the map requires that the underlying Mapbox Map canvas object is
        // fully loaded and ready. As such we use the field mapObjectReadyPromise to keep track
        // of its readiness.  This promise is resolved once the Mapbox Map object is ready for use.
        self.mapObjectReadyPromise = new Promise(function(resolve, reject){

            if (self.getMap()){
                console.log('Corrupted internal state. Map object already exists ?!');

                reject(new Error('Internal state of map viz is corrupted.'));
            }

            // validate and accept the map initialization options.
            
            if(typeof options['element'] === 'undefined') {
                throw 'Must specify a DOM element for the map to display in.';
            }
            self.element = options['element'];

            if(typeof options['initZoom'] !== 'undefined') {
                self.initZoom = options['initZoom'];
            }

            if(typeof options['initLon'] !== 'undefined') {
                self.initLon = options['initLon'];
            }

            if(typeof options['initLat'] !== 'undefined') {
                self.initLat = options['initLat'];
            }

            self.componentProperties = options['componentProperties'];

            self.currentMapStyle = self._validateMapStyle(options['basemap']);
            
            self.mapObject = new mapboxgl.Map({
                container: self.element,
                style: self.currentMapStyle,
                center: [self.initLon, self.initLat],
                zoom: self.initZoom,
                preserveDrawingBuffer: false
            });

            // promise is resolved once the Mapbox map instance is fully loaded.
            self.mapObject.on('load', function(){
                resolve(self.mapObject);
            });

            // use the map event 'moveend' to update the current map center position and zoom level.
            self.mapObject.on('moveend', function(){
                let centerPt = self.mapObject.getCenter();
                
                // update the component's writeback properties using the setProperty() API 
                if(self.componentProperties){
                    self.componentProperties.setProperty('center',{longitude:centerPt.lng,latitude:centerPt.lat});
                    self.componentProperties.setProperty('zoomLevel',self.mapObject.getZoom());
                }
            });

            // disable map tilt/rotation using right click + drag
            self.mapObject.dragRotate.disable();
 
            // disable map tilt/rotation using touch rotation gesture
            self.mapObject.touchZoomRotate.disableRotation();

        });

        return self.mapObjectReadyPromise;        
    };

    /**
     * Returns the Mapbox Map canvas object.
     */
    MapLogic.prototype.getMap = function() {
        return this.mapObject;
    };

    MapLogic.prototype.setMapZoomLevel = function(newZoomLevel){
        var self = this;
        // handle invalid values
        if(newZoomLevel<0 || newZoomLevel > 22)
            return;

        self.mapObjectReadyPromise.then(function(){
            self.mapObject.setZoom(newZoomLevel);
        });

    };

    MapLogic.prototype.setMapCenter = function(newCenter){
        var self = this;

        //Component min / max will prevent bad values so no need 
        //to re-validate

        self.mapObjectReadyPromise.then(function(){
            self.mapObject.setCenter([newCenter.longitude, newCenter.latitude]);
        });

    };

    MapLogic.prototype.setBaseMap = function(basemapName){
        if(!basemapName)
            return;

        var self = this;

        var newMapStyle = self._validateMapStyle(basemapName);

        // Do nothing since we are already showing the specified basemap.
        if(newMapStyle.id === self.currentMapStyle.id)
            return;


        self.mapObjectReadyPromise.then(function(){
            self.mapObject.setStyle(newMapStyle);
            self.currentMapStyle = newMapStyle;

            //restore all the dataset.
            self.restoreDatasets();
        });

    };

    // convenient method for validating that the user passed us a valid basemap name.
    // returns the corresponding or default map style object.
    MapLogic.prototype._validateMapStyle = function(basemapName){
        if(!basemapName)
            return this.defaultMapStyle;
        var uName = basemapName.toUpperCase();

        if(uName === 'DEFAULT')
            return this.defaultMapStyle;
        else if(uName === 'OSM_BRIGHT')
            return this.osmBrightMapStyle;
        else if(uName === 'OSM_POSITRON')
            return this.osmPositronMapStyle;
        else if(uName === 'OSM_DARKMATTER')
            return this.osmDarkmatterMapStyle;
        else {
            console.log('----> Invalid basemap specified.');
            return this.defaultMapStyle;
        }
    };

    MapLogic.prototype._validateDataset = function(dataset){
        if(!dataset)
            return null;

        var dsObj = dataset;
        if(typeof dataset === 'string') {
            dsObj = JSON.parse(dataset);
        }

        if(!dsObj)
            return null;

        if(!dsObj.name) {
            console.log('----> must specify a name for the dataset.');
            return null;
        }

        if(!dsObj.data) {
            console.log('----> must include data in the new dataset.');
            return null;
        }

        if(!dsObj.renderer) {
            console.log('----> must include renderer properties.');
            return null;
        }

        return dsObj;

    };

    // determines if a dataset with the given name already exists (added to the map) and if so
    // return its index in the array that caches them.
    MapLogic.prototype._indexOfDataset = function(dsName) {
        if(!dsName)
            return false;

        for(var i=0; i<this.existingDatasets.length; i++){
            var ds = this.existingDatasets[i];
            if( ds.name.toUpperCase() === dsName.toUpperCase() ){
                return i;
            }
        }

        return -1;
    };


    /**
     * Adds a dataset to the map to be displayed as a new map layer.
     *
     * This function accepts a single dataset object which must include the below properties:
     *
     * - name :  this is the unqiue (among the component) dataset or layer name.
     * - data :  this is an object conforming to the GeoJSON standard.
     * - renderer :  this is an object that defines how the dataset will be rendered on the map.
     *
     * Depending on the type of the renderer specified, this method invokes one of the concrete
     * methods to display the dataset on the map.
     * 
     * @param {Object} dataset The new dataset to be displayed. 
     * @param {Boolean} restoring  a flag indicating whether we are simply restoring a dataset
     *                              that was previously added by the application. Default is false.
     * @return {Boolean} true if the dataset was added to the map; false otherwise.
     */
    MapLogic.prototype.addDataset = function(dataset, restoring){
        const self = this;
        var dsObj = self._validateDataset(dataset);

        if(!dsObj)
            return false;

        if(self._indexOfDataset(dataset.name) >=0 && !restoring) {
            console.log('----> Error:  dataset with the name already exists: '+ dsObj.name);
            return false;
        }

        // different types of renderers are handled by different methods.
        // 
        var type = dsObj.renderer.type;
        var result = false;
        if(type==='symbol') {
            result = this._addPointDataset(dsObj, restoring);
        } else if(type==='line') {
            result = this._addLineDataset(dsObj, restoring);
        } else {
            console.log('----> Error: unknonw renderer type: '+ type);
        }


        return result;
    };

    /**
     * Function that will re-add all the existing dataset to the map after a basemap switch.
     * 
     * Note that the operation of basemap switch will clear out all existing map dataset sources and layers.
     * 
     */
    MapLogic.prototype.restoreDatasets = function(){
        for(var i=0; i<this.existingDatasets.length; i++){
            var dsObj = this.existingDatasets[i];

            this.addDataset(dsObj, true /* restoring */);
        }
    };

    /**
     * A helper method that adds a point-type dataset to the map.
     * @param {Object} dsObj  the dataset object.
     * @param {Boolean} restoring  the restoring flag.
     */
    MapLogic.prototype._addPointDataset = function(dsObj, restoring){
        const self = this;
        var map = self.mapObject;
        var renderer = dsObj.renderer;

        self.mapObjectReadyPromise.then(function(){

            map.loadImage(renderer.iconUrl, function(error, image) {
                if (error) 
                    throw error;

                // add the customer icon image to the map
                var imageName = 'image-'+self.nextImageIndex;
                self.nextImageIndex++;
                map.addImage(imageName, image);

                // add the new dataset's data as a source to the map.
                var sourceName = dsObj.name+'-src';
                map.addSource(sourceName,
                    {
                        'type': 'geojson',
                        'data': dsObj.data
                    });

                // create and add the new dataset to the map as a new layer.
                var layerName = dsObj.name+'-layer';
                var iconScale = typeof renderer.iconScale === 'undefined'? 1 : renderer.iconScale;
                map.addLayer({
                    'id': layerName,
                    'type': renderer.type,
                    'source': sourceName,
                    'layout': {
                        'icon-image': imageName,
                        'icon-size': iconScale
                    }
                });

                //cache the dataset object. 
                if(!restoring)
                    self.existingDatasets.push(dsObj);


                if(renderer.zoomToData && !restoring){
                    // do nothing if the 'data' property contains a URL string (to a remote GeoJSON document).
                    if(typeof dsObj.data === 'object') {
                        var ext = getGeoJsonExtent(dsObj.data);
                        if(ext){
                            // enlarge ext by 10%, then zoom the map to the enlarged extent.
                            map.fitBounds(scaleExtentBy(ext, 0.1));
                        }
                    }
                }                

            });

            //end of self.mapObjectReadyPromise.then
        });        
    };

    /**
     * A helper method that adds a line-type dataset to the map.
     * @param {Object} dsObj  the dataset object.
     * @param {Boolean} restoring  the restoring flag.
     */
    MapLogic.prototype._addLineDataset = function(dsObj, restoring){
        const self = this;
        var map = self.mapObject;
        var renderer = dsObj.renderer;

        self.mapObjectReadyPromise.then(function(){

            // add the new dataset's data as a source to the map.
            var sourceName = dsObj.name+'-src';
            map.addSource(sourceName,
                {
                    'type': 'geojson',
                    'data': dsObj.data
                });

            // create and add the new dataset to the map as a new layer.
            var layerName = dsObj.name+'-layer';

            var lineColor = renderer.lineColor || '#800';
            var lineWidth = renderer.lineWidth || 2;
            var lineJoin = renderer.lineJoin || 'round';
            var lineCap = renderer.lineCap || 'round';
            var lineOpacity = (typeof renderer.lineOpacity === 'undefined')? 1 : renderer.lineOpacity; 

            map.addLayer({
                'id': layerName,
                'type': renderer.type,
                'source': sourceName,
                'layout': {
                    'line-join': lineJoin,
                    'line-cap': lineCap
                },
                'paint': {
                    'line-color': lineColor,
                    'line-width' : lineWidth,
                    'line-opacity': lineOpacity
                }
            });


            //cache the dataset object
            if(!restoring)
                self.existingDatasets.push(dsObj);

            if(renderer.zoomToData && !restoring){
                // do nothing if the 'data' property contains a URL string (to a remote GeoJSON document).
                if(typeof dsObj.data === 'object') {
                    var ext = getGeoJsonExtent(dsObj.data);
                    if(ext){
                        // enlarge ext by 10%, then zoom the map to the enlarged extent.
                        map.fitBounds(scaleExtentBy(ext, 0.1));
                    }
                }
            }

            //end of self.mapObjectReadyPromise.then
        });
    };

    /**
     * Removes a dataset with the given name from the map.
     * @param  {[type]} name [description]
     * @return {[type]}      [description]
     */
    MapLogic.prototype.removeDataset = function(name){
        const self = this;
        var map = self.mapObject;

        var idx = self._indexOfDataset(name);
        if(idx <0)
            return;

        var layerName = name+'-layer';
        var sourceName = name+'-src';
        self.mapObjectReadyPromise.then(function(){

            map.removeLayer(layerName);
            map.removeSource(sourceName);
            self.existingDatasets.splice(idx,1);
        });
    };

    MapLogic.prototype.removeAllDatasets = function(){
        const self = this;
        var map = self.mapObject;
        var dsNames = [];
        for(var i=0; i<self.existingDatasets.length; i++){
            dsNames.push(self.existingDatasets[i].name);
        }

        for(var i=0; i<dsNames.length; i++){
            self.removeDataset(dsNames[i]);
        }

        self.existingDatasets = [];
    };

    /**
     * Gets the extent (bounding box) of all the features in the provided GeoJSON.
     * Returns null if there is no feature found in the GeoJSON.
     */
    function getGeoJsonExtent(json){
        var ext = null;
        var foundValidExtent = false;

        var features = json.features;
        if(!features || features.length==0)
            return null;

        for(var i=0; i<features.length; i++){
            var f = features[i];

            var fExt = getFeatureExtent(f);
            if(!fExt)
                continue;

            if(!foundValidExtent){
                ext = fExt;
                foundValidExtent = true;
            } else {
                extend(ext, fExt);
            }
        }

        return ext;
    }

    // utility method that calculates the bounding box (geographic extent) of
    // a feature.  result array contains [xMin, yMin, xMax, yMax].
    function getFeatureExtent(f){
        var geom = f.geometry;
        if(!geom)
            return null;

        var type = geom.type;
        var coords = geom.coordinates;

        switch(type.toUpperCase()){
            case 'POINT': return getPointExtent(coords);
            case 'LINESTRING': return getLineStringExtent(coords);
            case 'POLYGON' : return getPolygonExtent(coords);
            case 'MULTIPOINT' : return getMultiPointExtent(coords);
            case 'MULTILINESTRING' : return getMultieLineStringExtent(coords);
            case 'MULTIPOLYGON' : return getMultiPointExtent(coords);            
            case 'GEOMETRYCOLLECTION' : 
            default:
                return null; 
        }
    }

    // extends the extent 'ext1' so that it includes the extent of 'ext2'.
    // values in 'ext1' will be modified as needed.
    function extend(ext1, ext2){
        if(!ext1 || !ext2)
            return;

        ext1[0] = ext1[0] > ext2[0]? ext2[0] : ext1[0]; // xmin
        ext1[1] = ext1[1] > ext2[1]? ext2[1] : ext1[1]; // ymin
        ext1[2] = ext1[2] < ext2[2]? ext2[2] : ext1[2]; // xmax
        ext1[3] = ext1[3] < ext2[3]? ext2[3] : ext1[3]; // ymax
    }

    // enlarge or shrink the extent by the specified scaling factor. Scaling factor of 1
    // means no change; 0.5 means shrink the extent by 50%, while 2 means enlarge the
    // extent by twice.
    // The ext parameter's values will be modified in place.
    function scaleExtentBy(ext, scalingFactor){
        if(!ext || scalingFactor===1 || scalingFactor===0)
            return ext;

        var width = ext[2] - ext[0];
        var height = ext[3] - ext[1];

        var deltaW = width * scalingFactor / 2;
        var deltaH = height * scalingFactor / 2;

        ext[0] = ext[0] - deltaW;
        ext[1] = ext[1] - deltaH;
        ext[2] = ext[2] + deltaW;
        ext[3] = ext[3] + deltaH;

        return ext;
    }

    function getPointExtent(coords){
        if(!coords || coords.length==0)
            return null;

        return [ coords[0], coords[1], coords[0], coords[1] ];
    }

    // Ring = a single LineString, or a single closed ring in a Polygon. 
    function getRingExtent(coords){
        if(!coords || coords.length==0)
            return null;

        var pair = coords[0];
        var xmin=pair[0], ymin=pair[1], xmax=pair[0], ymax=pair[1];
        
        for(var i=1; i<coords.length; i++){
            var pair = coords[i];
            xmin = xmin > pair[0]? pair[0] : xmin;
            ymin = ymin > pair[1]? pair[1] : ymin;
            xmax = xmax < pair[0]? pair[0] : xmax;
            ymax = ymax < pair[1]? pair[1] : ymax;
        }

        return [xmin,ymin,xmax,ymax];
    }

    function getLineStringExtent(coords) {
        return getRingExtent(coords);
    }

    // A Polygon always has one (outer) ring,
    // plus zero or more interior rings (holes).
    function getPolygonExtent(coords){
        var xmin = 0, ymin = 0, xmax = 0, ymax = 0;
        var foundValidExtent = false;

        for(var i=0; i<coords.lenth; i++){
            var ring = coords[i];

            var ringExt = getRingExtent(ring);
            if(!ringExt)
                continue;

            if(!foundValidExtent) {
                [xmin,ymin,xmax,ymax] = ringExt;
                foundValidExtent = true;
            } else {
                xmin = xmin > ringExt[0]? ringExt[0] : xmin;
                ymin = ymin > ringExt[1]? ringExt[1] : ymin;
                xmax = xmax < ringExt[0]? ringExt[0] : xmax;
                ymax = ymax < ringExt[1]? ringExt[1] : ymax;
            }
        }

        return foundValidExtent?  [xmin,ymin,xmax,ymax] : null;
    }


    function getMultiPointExtent(coords){
        //multipoint geometry's coordinates are organized the same as a ring.
        return getRingExtent(coords);
    }

    function getMultiLineStringExtent(coords){
        //structurally speaking, a MultiLineString's coordinates are organized the same as a Polygon.
        return getPolygonExtent(coords);
    }

    function getMultiPolygonExtent(coords){
        var xmin = 0, ymin = 0, xmax = 0, ymax = 0;

        var foundValidExtent = false;

        for(var i=0; i<coords.length; i++){
            var polygon = coords[i];

            var polygonExt = getPolygonExtent(polygon);
            if(!polygonExt)
                continue;

            if(! foundValidExtent){
                [xmin,ymin,xmax,ymax] = polygonExt;
                foundValidExtent = true;
            } else {
                xmin = xmin > polygonExt[0]? polygonExt[0] : xmin;
                ymin = ymin > polygonExt[1]? polygonExt[1] : ymin;
                xmax = xmax < polygonExt[0]? polygonExt[0] : xmax;
                ymax = ymax < polygonExt[1]? polygonExt[1] : ymax;                
            }
        }

        return foundValidExtent? [xmin,ymin,xmax,ymax] : null;
    }


    return MapLogic;
});