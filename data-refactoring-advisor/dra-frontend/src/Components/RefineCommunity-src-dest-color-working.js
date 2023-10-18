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
  const [nodes, setNodes] = useState([]);

  const [source, setSource] = useState("");
  const [destination, setDestination] = useState("");
  const [destinationArray, setDestinationArray] = useState([]);
  const [destinations, setDestinations] = useState([]);
  
  const [sourceValue, setSourceValue] = useState("");
  const [destinationValue, setDestinationValue] = useState("");

  const [selectedCard, setSelectedCard] = "";
  const location = useLocation();
  let graphData =  JSON.parse(location.state.graphData);
  
  let sqlSetName = location.state.stsName;

  useEffect(() => {
    console.log("UseEffect Calling, Values :: "+ values)
    setNodes(graphData.nodes);
  },[]);
  
  function fetchDestinations() {
    let arrayTemp = [];
    const data = groupBy(graphData.nodes, 'color');
    const destinations = [...new Set(Object.keys(data).map(objKey => objKey))];
    destinations.map((item) => {
      arrayTemp.push({"color":item})
    })
    setDestinationArray(arrayTemp);
    const destinations1 = arrayTemp.map((item) => item.color);
    setDestinations(destinations1);
  }

  function handleSourceChange (e) {
    setSource(e.target.value);
    setSourceValue(e.target.value);
    fetchDestinations();
    setDestination(null);
    setDestinationValue(null);
  };
  
  // handle change event of the destination dropdown
  const handleDestinationChange = (e) => {
    setDestination(e.target.value);
    setDestinationValue(e.target.value);
  };

  var groupBy = function(xs, key) {
    return xs.reduce(function(rv, x) {
      (rv[x[key]] = rv[x[key]] || []).push(x);
      return rv;
    }, {});
  };

  const handleAdd = () => {
    const newValues = [...values];
    newValues.push({ "name":sourceValue, "color":destinationValue });
    setValues(newValues);

    const updatedNodes = nodes.filter((item) => item.name !== sourceValue);
    setNodes(updatedNodes);

    setSource("");
    setDestination("");
    setSourceValue("");
    setDestinationValue("");
  };

  function removeEntry(sourceToRemove) {
    const newList = values.filter((item) => item.name !== sourceToRemove);
    setValues(newList);
    const removedNode = graphData.nodes.filter((item) => item.name === sourceToRemove);
    nodes.push(removedNode[0]);
    setNodes(nodes);
  }
  
  const handleRefineClick = async (stsName) => {
    var myHeaders = new Headers();
    myHeaders.append("Content-Type", "application/json");

    var raw = JSON.stringify({
      refineNodesList:values,
      sqlSetName: stsName,
    });
    
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
              
              <select className="form-input" id="source" value={source} onChange={(e) => handleSourceChange(e)}>
                <option>
                  --Select Source--
                </option>
                {nodes.map(d=>(
                  <option value={d.name}>{d.name}</option>
                ))}
              </select>
            </div>
            <div className="form-row">
              <label htmlFor="destination" className="form-label">
                  Select Destination Community Color:
              </label> 
              <select className="form-input" id="destination" value={destination} onChange={(e) => handleDestinationChange(e)}>
                <option>
                  --Select Destination Color
                </option>
                {destinationArray.map(d=>(
                  <option value={d.color}>{d.color}</option>
                ))}
              </select>
            </div>
          
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
