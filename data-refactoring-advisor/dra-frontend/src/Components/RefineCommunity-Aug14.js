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
  const [nodes, setNodes] = useState([]);

  const [source, setSource] = useState("");
  const [destination, setDestination] = useState("");
  const [destinations, setDestinations] = useState([]);
  const [destinationArray, setDestinationArray] = useState([]);

  const [affinity, setAffinity] = useState("");

  const [sourceValue, setSourceValue] = useState("");
  const [destinationValue, setDestinationValue] = useState("");

  const [selectedCard, setSelectedCard] = "";
  const location = useLocation();
  //let refineCommunityData =  JSON.parse(location.state.refineCommunityData);
  let graphData =  JSON.parse(location.state.graphData);
  let sqlSetName = location.state.stsName;

  useEffect(() => {
    fetchSources(); 
  },[]);
  
  function fetchSources() {

    const nodes =  JSON.parse(location.state.graphData.nodes);
    setNodes(nodes);

    /*const sources1 = [...new Set(refineCommunityData.map((item) => item.source))];
    setSources(sources1)*/
    const sources1 = [...new Set(graphData.nodes.map((item) => item.name))];
    
    /*const newList = values.filter((item) => 
      sources1.dele
      item.name !== sourceToRemove
    );*/
    
    //setSources(sources1)
  }

  function fetchDestinations() {
    let arrayTemp = [];
   // GFG["prop_4"] = "val_4";
    const data = groupBy(graphData.nodes, 'color');
    const destinations = [...new Set(Object.keys(data).map(objKey => objKey))];
    destinations.map((item) => {
      console.log("Dest item == " + item);
      arrayTemp.push({"color":item})
    })
    setDestinationArray(arrayTemp);
    const destinations1 = arrayTemp.map((item) => item.color);
    setDestinations(destinations1);
  }

  function handleSourceChange (e) {
    setSource(e);
    setSourceValue(e.name);
    //const destinations = refineCommunityData.filter((item) => item.source === e.source);
    //const selectedDestinations = e.destinations.map((itemDest) => itemDest.table2);
    fetchDestinations();
    //setDestinations(destinations);
    setDestination(null);
    console.log("Values in Source change = " + JSON.stringify(values));
    setDestinationValue(null);
  };
  
  // handle change event of the destination dropdown
  const handleDestinationChange = (obj) => {
    setDestination(obj);
    setDestinationValue(obj.color);
  };

  var groupBy = function(xs, key) {
    return xs.reduce(function(rv, x) {
      (rv[x[key]] = rv[x[key]] || []).push(x);
      return rv;
    }, {});
  };

  const handleAdd = () => {
    const newValues = [...values];
    console.log("handleAdd, source :: " + sourceValue);
    console.log("handleAdd, destination :: " + destinationValue);
    newValues.push({ "name":sourceValue, "color":destinationValue });
    setValues(newValues);

    console.log("sourceValue :: " + sourceValue);
    debugger
    //const updatedSources = [...sources];
    const updatedNodes = nodes.filter((item) => item.name !== sourceValue);
    console.log("updatedNodes :: " + updatedNodes);
    //setSources(newUpdatedSources);
    setNodes(updatedNodes);

    setSource("");
    setDestination("");
    setAffinity("");
    setSourceValue("");
    setDestinationValue("");
  };

  function removeEntry(sourceToRemove) {
    const newList = values.filter((item) => item.name !== sourceToRemove);
    setValues(newList);
    
  }
  
  const handleRefineClick = async (stsName) => {
    // code for refining the values
    console.log("In handleRefineClick, stsName :: " + stsName);
    var myHeaders = new Headers();
    myHeaders.append("Content-Type", "application/json");

    console.log("Values in Request = " + JSON.stringify(values));
    var raw = JSON.stringify({
      refineNodesList:values,
      sqlSetName: stsName,
    });
    console.log("Input Request raw = " + raw);

    var requestOptions = {
      method: "POST",
      headers: myHeaders,
      body: raw,
      redirect: "follow",
    };

    let response = await fetch(
      "http://localhost:8080/api/refinecommunity",
      requestOptions
    );
    let data = await response.text();
    console.log(data);
    //setResult(data);
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
                placeholder="Select Source"
                value={source}
                /*options={refineCommunityData}*/
                options={nodes}
                onChange={(e) => handleSourceChange(e)}
                getOptionLabel={x => x}
                getOptionValue={x => x}
              />
            </div>
            <div className="form-row">
              <label htmlFor="destination" className="form-label">
                  Select color of Destination Community:
              </label>
              <Select className="form-input" id="source"
                placeholder="Select Destination"
                value={destination}
                options={destinationArray}
                onChange={(e) => handleDestinationChange(e)}
                getOptionLabel={x => x.color}
                getOptionValue={x => x.color}
              />
            </div>
            {/*<div className="form-row">
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
            </div>*/}
            <br />
            <div className="form-row" align-items="center">
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
                    Source Node
                  </th>
                  <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
                    Destination Community Color
                  </th>
                  <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
                    Actions
                  </th>
                  {/*<th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
                    Affinity Values
                    </th>*/}
                </tr>
              </thead>
              <tbody>
                {values.map(({name,color}) => (
                  <tr key={name}>
                    <td>{name}</td>
                    <td>{color} </td>
                    <td><button onClick={()=>removeEntry(name)}>X</button></td>
                    
                  </tr>
                ))}
              </tbody>
            </table>

            {values !== null && (
              <button className="btn" onClick={()=>handleRefineClick(sqlSetName)}>
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
