/*
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

define(
    [
        'ojs/ojcontext',
        './mapLogic',
        'ojs/ojknockout',

    ],
    function (Context, MapLogic) {
        const MAP_CONTAINER_ID_PREFIX = 'map-container-';

        // known basemaps that are available from the Oracle cloud service.
        const ORACLE_BASEMAPS = {
            'elocation-osm-bright-raster': 'elocation-osm-bright-raster',
            'elocation-osm-darkmatter-raster': 'elocation-osm-darkmatter-raster',
            'elocation-osm-positron-raster': 'elocation-osm-positron-raster',
            'elocation-mercator-worldmap-mb': 'elocation-mercator-worldmap-mb'
        };

        function OracleMapsBasicViewModel(context) {
            var self = this;

            // the id of the DIV where map contents will be displayed.
            self.mapDivId = MAP_CONTAINER_ID_PREFIX + Math.random().toString(36).substr(2, 9);

            //At the start of your viewModel constructor
            var busyContext = Context.getContext(context.element).getBusyContext();
            var options = { "description": "Web Component Startup - Waiting for map to initialize." };
            self.busyResolve = busyContext.addBusyState(options);

            self.composite = context.element;
            self.properties = context.properties;

            self.mapLogic = null;

        }

        /**
         * Display the map with a basemap and the initial dataset once the component's bindings have been applied.
         */
        OracleMapsBasicViewModel.prototype.bindingsApplied = function (context) {
            const self = this;
            if (self.mapLogic)
                return;

            var elem = document.getElementById(self.mapDivId);

            self.mapLogic = new MapLogic({ element: elem });

            // get the map options based on the component tag attributes.
            var mapOpts = {
                element: elem,
                initZoom: self.properties.zoomLevel,
                initLon: self.properties.center.longitude,
                initLat: self.properties.center.latitude,
                basemap: self.properties.basemap,
                componentProperties: self.properties                
            };

            // initialize the map display using the application specified options.
            var mapLoaded = self.mapLogic.initializeMap(mapOpts);

            mapLoaded.then(function () {
                //resolve the busy context once map has been initialized.
                self.busyResolve();
            });

            // add the initial dataset passed in as a component tag attribute, if any
            if (self.properties.dataset) {
                self.mapLogic.addDataset(self.properties.dataset);
            }

        };

        /**
         * Lifecycle callback triggered when any bound property value changes 
         * Generally used to detect updates to external variables that will need the 
         * component to react in some way
         */
        OracleMapsBasicViewModel.prototype.propertyChanged = function (context) {
            var self = this;
            if (context.updatedFrom === 'external') {
                switch (context.property) {
                    case 'zoomLevel':
                        self.mapLogic.setMapZoomLevel(context.value);
                        break;
                    case 'center':
                        self.mapLogic.setMapCenter(context.value);
                        break;
                    case 'basemap':
                        self.mapLogic.setBaseMap(context.value);
                        break;
                }
            }
        };



        // Registered, public methods of the component. These methods are simple
        // proxies to the real implementation in the MapLogic class.

        /**
         * Adds a new dataset to the map to be displayed as a new layer.
         * 
         * See the corresponding method in mapLogic.js for detailed documentation.
         * 
         */
        OracleMapsBasicViewModel.prototype.addDataset = function (def) {
            const self = this;

            if (!self.mapLogic) {
                console.log('---> Error: map not initialized yet.');
                return;
            }

            self.mapLogic.addDataset(def);
        }

        /**
         * Removes a given dataset from the map.
         * @param  {String} name name of the dataset to be removed.
         */
        OracleMapsBasicViewModel.prototype.removeDataset = function (name) {
            const self = this;

            if (!self.mapLogic) {
                console.log('---> Error: map not initialized yet.');
                return;
            }

            self.mapLogic.removeDataset(name);
        }

        /**
         * Removes a named dataset (has to have been programmatically added in the first place) from the map. 
         */
        OracleMapsBasicViewModel.prototype.removeAllDatasets = function () {
            const self = this;

            if (!self.mapLogic) {
                console.log('---> Error: map not initialized yet.');
                return;
            }

            self.mapLogic.removeAllDatasets();
        }        


        /**
         * Removes all datasets from the map. This includes the initial dataset passed in
         * as a tag attribute, as well as any programmatically added datasets.
         */
        OracleMapsBasicViewModel.prototype.removeAllDatasets = function () {
            const self = this;

            if (!self.mapLogic) {
                console.log('---> Error: map not initialized yet.');
                return;
            }

            self.mapLogic.removeAllDatasets();
        }

        return OracleMapsBasicViewModel;
    });