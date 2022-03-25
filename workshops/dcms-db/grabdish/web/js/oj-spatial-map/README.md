/*
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
 # oj-spatial-map - The standalone Jet Web component for mapping

This is the basic Web component for displaying a map.

The web component will initialize a map canvas object (which is an instance of the Mapbox GL JS API's [Map class](https://docs.mapbox.com/mapbox-gl-js/api/#map)).

The map canvas will always display a map background (basemap), whose contents are hosted on Oracle's own public Map Cloud
service.  There are 4 different types or themes of basemaps as shown below. 

You can display one or more interactive datasets (commonly known as map layers in the GIS world) on top of the basemap.

### Tag attributes

The component provides the below tag attributes, all are optional:

- **center** : the initial map center point; contains two sub-properties: **longitude** and **latitude**. 
- **zoom-level** : the initial map zoom level; an integer ranging 0 - 18
- **basemap**    : the initial basemap; possible values are **default**, **osm_bright**, **osm_positron**, and **osm_darkmatter**.
- **dataset**    : the initial map dataset to display; an object.

### Component methods

The component provides the below public methods:

- **addDataset** : this methiod allows application to programmatically add a new dataset to the map. Each new dataset
    is displayed on the map as a new map layer.
- **removeDataset** : this method removes an existing dataset from the map.
- **removeAllDatasets** : this method removes all previously added datasets from the map.
- **switchBasemap**  : this method allows application to programmatically switch the basemap displayed.

### Key Concepts: dataset

The key concept is dataset.

A dataset is simply a JavaScript object that represents a set of geographic features of similar type or 
characteristics.  For instance all my customers. Or all the pizza shops near me.  You can have one or more datasets
displayed on the same map at any given time.

When you want to add a dataset to the map, you have two ways of doing so. One is by passing your dataset object as a 
component tag attribute, the other is by programmatically (such as in response to a user initiated action) adding 
a dataset using the component's public method **addDataset()**.


### Structure of a dataset.

Each dataset must have these three aspects clearly defined:

- **name** :  each dataset must have a unqiue name (unique within the map ) string.
- **data** :  contains the actual geographic data, or more commonly known as features. Each feature includes a
     location/geometry, as well as properties (such as customer name, contact phone number et al.) This is typically
     a GeoJSON object, or URL to a GeoJSON document. See the [GeoJSON spec here](https://en.wikipedia.org/wiki/GeoJSON).
- **renderer** : an object containing properties that define how exactly the data in the dataset will be displayed on the
    map. Mapbox GL JS refers to such properties as the 'layout' and/or 'paint'.  Note that while the web component dataset's **renderer**
    properties may look very similar to those of Mapbox's 'layout' or 'paint' properties, they are not always the same as the 
    web component attempts to hide away some of the complexities.

Note that additional customizable properties will be added down the road, such as properties that define the 'legend' as well as
the 'pop-up' window of a dataset.

### Properties of a dataset's renderer

As noted above, each dataset must have a 'renderer' object that defines clearly how the data in that dataset should
be rendered, or laid out, on a map.

The most important property of a dataset's renderer is its **type**. The renderer type determines how the geographic features
will be represented visually on the map, whether as symbols, heatmaps, circles, (polygon) fills or line strokes.

The below is a list of the possible properties of a 'renderer' object. Note that not all the properties make sense for all types of
renderers.

- **type** :  this is a required property that must be specified for all types of renderers. Supported values are 
    **symbol**, **line** and **fill**.
- **zoomToData**: this is an optional property with default value of false. If set to true, then the map will be fit
                 to the bounding box of the dataset's features.
- **iconUrl** : this property is only used when the type is 'symbol', and it is a URL to a custom image icon.
- **iconScale** : this property is only used when the type is 'symbol', and it represents the scaling factor of the icon
    image. A scale value of 1 means the custom image will be displayed on the map using its original dimension, while
    a scale of 0.5 means the original image will be scaled down by half when displayed.
- **lineColor** : this property is only used when the type is 'line'.
- **lineWidth** : this property is only used when the type is 'line'.
- **lineOpacity** : this property is only used when the type is 'line'; value ranges from 0 to 1.