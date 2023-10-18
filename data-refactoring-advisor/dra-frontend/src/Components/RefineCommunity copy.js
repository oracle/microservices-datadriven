// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import React, { useState, useEffect} from "react";
import { Link } from "react-router-dom";
import Select from "react-select";
//import { Link, useNavigate } from "react-router-dom";
import "../Css/styles.css";
import { useLocation } from "react-router-dom";
//import Pagination from "react-responsive-pagination";

function RefineCommunity() {

  const [values, setValues] = useState([]);
  const [sources, setSources] = useState([]);

  const [source, setSource] = useState("");
  const [destination, setDestination] = useState("");
  const [destinations, setDestinations] = useState([]);

  const [affinity, setAffinity] = useState("");

  const [sourceValue, setSourceValue] = useState("");
  const [destinationValue, setDestinationValue] = useState("");

  const [selectedCard, setSelectedCard] = "";
  const location = useLocation();
  //let refineCommunityData =  JSON.parse(location.state.refineCommunityData);
  let graphData =  JSON.parse(location.state.graphData);
  

  useEffect(() => {
    fetchSources();
    fetchDestinations();
  }, []);
  
  function fetchSources() {
    /*const sources1 = [...new Set(refineCommunityData.map((item) => item.source))];
    setSources(sources1)*/
    const sources1 = [...new Set(graphData.nodes.map((item) => item.name))];
    console.log("sources1 = " + sources1);
    console.log("Type of sources1 = " + typeof(sources1));
    setSources(sources1)
  }

  function fetchDestinations() {
    const data = groupBy(graphData.nodes, 'color');
    setDestinations(data);
  }

  function handleSourceChange (e) {
    console.log("Changed Source :: "+e.source);
    setSource(e);
    setSourceValue(e.source);

    //const destinations = refineCommunityData.filter((item) => item.source === e.source);
    //const selectedDestinations = e.destinations.map((itemDest) => itemDest.table2);
    debugger
    setDestinations(destinations);
    //setDestination(null);
    setDestinationValue(null);
  };
  
  // handle change event of the destination dropdown
  const handleDestinationChange = (obj) => {
    debugger
    setDestination(obj);
    setAffinity(obj.total_affinity);
    setDestinationValue(obj.table2);
  };

  var groupBy = function(xs, key) {
    return xs.reduce(function(rv, x) {
      (rv[x[key]] = rv[x[key]] || []).push(x);
      return rv;
    }, {});
  };

  /*var renderDataVar = function () {
    const data = groupBy(graphData.nodes, 'color');
    return Object.keys(data).map(objKey => 
      <tr key={objKey}> 
        <td><Circle color={objKey}> </Circle></td>
        <td>{data[objKey].map((item,index) => (index===0 ? item.name : ", " +item.name))}</td>
      </tr>
 )};*/

  let sqlSetName = location.state.stsName;
  const handleAdd = () => {
    const newValues = [...values];
    console.log("handleAdd, source :: " + sourceValue);
    console.log("handleAdd, destination :: " + destinationValue);
    console.log("handleAdd, affinity :: " + affinity);
    newValues.push({ sourceValue, destinationValue, affinity });
    setValues(newValues);
    setSource("");
    setDestination("");
    setAffinity("");
    setSourceValue("");
    setDestinationValue("");
  };


  
  
  /*const handleSourceChange = (event) => {
    setSource(event.target.value);    
  };

  const handleDestinationChange = (event) => {
    setDestination(event.target.value);
  };

  const handleAffinityChange = (event) => {
    setAffinity(event.target.value);
  };*/

  

  const handleRefine = () => {
    // code for refining the values
  };

  return (
    <div className="form-container">
      <div className="form">
        <h4>Refine Community:</h4>

        <div style={{ display: "flex" }}>
          <Link to="/community">
            <button
              className="btn-cross btn-cross-form"
              onClick={() => setSelectedCard(null)}
            >
              X
            </button>
          </Link>
          <br />
          <br />
          <div>
            <br />
            <br />

            <br />
            <div className="form-row">
              <label htmlFor="source" className="form-label">
                Select the Source Entity:
              </label>
              <Select className="form-input" id="source"
                placeholder="Select Source:"
                value={source}
                /*options={refineCommunityData}*/
                options={graphData.nodes}
                onChange={(e) => handleSourceChange(e)}
                getOptionLabel={x => x.source}
                getOptionValue={x => x.source}
              />
            </div>
            <div className="form-row">
              <label htmlFor="destination" className="form-label">
                  Select the Destination Entity:
              </label>
              <Select className="form-input" id="source"
                placeholder="Select Destination"
                value={destination}
                options={destinations}
                onChange={(e) => handleDestinationChange(e)}
                getOptionLabel={x => x.table2}
                getOptionValue={x => x.table2}
              />
            </div>
            <div className="form-row">
              <label htmlFor="affinity" className="form-label">
                Enter the Affinity value(0-1):
              </label>
              <input
                type="text"
                className="form-input"
                id="affinity"
                required
                value={affinity}
                onChange={(e) => setAffinity(e.target.value)}
              />
            </div>
            <br />
            <div className="form-row">
              <button type="submit" className="btn" onClick={()=>handleAdd()}>
                +ADD
              </button>
            </div>
          </div>
          <div>
            <br />
            <br />

            <br />
            <table className="table">
              <thead>
                <tr className="tr">
                  <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
                    Source
                  </th>
                  <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
                    Destination
                  </th>
                  <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
                    Affinity Values
                  </th>
                </tr>
              </thead>
              <tbody>
                {values.map(({sourceValue,destinationValue,affinity}) => (
                  <tr key={source}>
                    <td>{sourceValue}</td>
                    <td>{destinationValue} </td>
                    <td>{affinity}</td>
                  </tr>
                ))}
              </tbody>
            </table>

            {values !== null && (
              <button className="btn" onClick={handleRefine}>
                Refine
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default RefineCommunity;
