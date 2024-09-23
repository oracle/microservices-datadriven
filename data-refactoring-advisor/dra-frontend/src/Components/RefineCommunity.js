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
  const location = useLocation();
  const [values, setValues] = useState([]);
  //const [nodes, setNodes] = useState([]);
  const [sources, setSources] = useState([]);

  const [source, setSource] = useState("");
  const [destination, setDestination] = useState("");
  const [destinationArray, setDestinationArray] = useState([]);
  const [destinations, setDestinations] = useState([]);
  
  const [sourceValue, setSourceValue] = useState("");
  const [destinationValue, setDestinationValue] = useState("");
  const [affinity, setAffinity] = useState("");

  const [selectedCard, setSelectedCard] = useState(null);
  const [result, setResult] = useState("");

  //let graphData =  JSON.parse(location.state.graphData);
  let refineCommunityData =  JSON.parse(location.state.refineCommunityData);
  let sqlSetName = location.state.stsName;

  useEffect(() => {
    fetchSources();
  },[]);

  function fetchSources() {
    const sources1 = [...new Set(refineCommunityData.map((item) => item.source))];
    console.log(sources1);

    const newSources = ["--Select Source--"].concat(sources1);
    setSources(newSources);
  }
  
  /*function fetchDestinations() {
    let arrayTemp = [];
    const data = groupBy(graphData.nodes, 'color');
    const destinations = [...new Set(Object.keys(data).map(objKey => objKey))];
    destinations.map((item) => {
      arrayTemp.push({"color":item})
    })
    setDestinationArray(arrayTemp);
    const destinations1 = arrayTemp.map((item) => item.color);
    setDestinations(destinations1);
  }*/

  function handleSourceChange (obj) {
    console.log(obj.target.value);
    setSource(obj.target.value);
    const destinations1 = refineCommunityData.find((item) => item.source === obj.target.value).destinations;
    setDestinations(destinations1);
    setAffinity('');
    /*setSource(e.target.value);
    setSourceValue(e.target.value);
    fetchDestinations();
    setDestination(null);
    setDestinationValue(null);*/
  };
  
  // handle change event of the destination dropdown
  const handleDestinationChange = (e) => {
    setDestination(e.target.options[e.target.selectedIndex].text);
    setAffinity(e.target.value);
    //setDestinationValue(e.target.value);
  };

  var groupBy = function(xs, key) {
    return xs.reduce(function(rv, x) {
      (rv[x[key]] = rv[x[key]] || []).push(x);
      return rv;
    }, {});
  };

  const handleAdd = (e) => {
    const newValues = [...values];
    newValues.push({ source, destination, affinity });
    setValues(newValues);
    setSource('');
    setDestination('');
    setAffinity('');
    setDestinations([]);
    setSources([]);
    fetchSources();

    /*const newValues = [...values];
    newValues.push({ "name":sourceValue, "color":destinationValue });
    setValues(newValues);

    const updatedNodes = nodes.filter((item) => item.name !== sourceValue);
    setNodes(updatedNodes);

    setSource("");
    setDestination("");
    setSourceValue("");
    setDestinationValue("");*/
  };

  function removeEntry(sourceNode, destNode) {
    /*const newList = values.filter((item) => item.name !== sourceToRemove);
    setValues(newList);
    const removedNode = graphData.nodes.filter((item) => item.name === sourceToRemove);
    nodes.push(removedNode[0]);
    setNodes(nodes);*/
    debugger
    const newList = values.filter((item) => (item.source !== sourceNode && item.destination !== destNode));
    setValues(newList);
  }
  
  const handleRefineClick = async (stsName) => {
    var myHeaders = new Headers();
    myHeaders.append("Content-Type", "application/json");

    var raw = JSON.stringify({
      //refineNodesList:values,
      nodesList:values,
      sqlSetName: stsName,
    });
    
    console.log(raw);
    var requestOptions = {
      method: "POST",
      headers: myHeaders,
      body: raw,
      redirect: "follow",
    };

    let response = await fetch(
      "http://localhost:8080/api/refinecommunity",
      requestOptions
    ).then((response) => {
      setSelectedCard(true);
      if (response.ok) {
        setResult("Refine Community Completed Successfully for '"+ stsName + "'");
      } else {
        setResult("Error in Refine Community for '"+ stsName + "'");
      }
      setSelectedCard(false);
    }).catch((error) => {
      console.error("Error in Refine Community:", error);
      setSelectedCard(true);
      setResult(error);
      setSelectedCard(false);
    });
    //let data = await response.text();
    //console.log(data);
    //setResult(data);
  };

  return (
    <div className="form-container">
      <div className="form">
        <div><h4>Refine Community for SQL Tuning Set : {sqlSetName} </h4></div>

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
              
              <select className="form-input" id="source" onChange={(e) => handleSourceChange(e)}>
                
                {sources.map(d=>(
                  <option value={d}>{d}</option>
                ))}
              </select>
            </div>
            <div className="form-row">
              <label htmlFor="destination" className="form-label">
                  Select the Destination Entity:
              </label> 
              <select className="form-input" id="destination" onChange={(d) => handleDestinationChange(d)}>
                <option>
                  --Select Destination--
                </option>
                {destinations.map(d=>(
                  <option value={d.total_affinity}>{d.table2}</option>
                ))}
              </select>
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
            <div className="form-row" align-items="center">
              <button type="submit" className="btn" onClick={(e)=>handleAdd(e)}>
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
                    Destination Node
                  </th>
                  <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
                    Affinity
                  </th>
                  <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody>
              {
                values.map((value, index) => (
                  <tr key={index}>
                    <td>{value.source}</td>
                    <td>{value.destination} </td>
                    <td>{value.affinity}</td>
                    <td><button onClick={()=>removeEntry(value.source, value.destination)}>X</button></td>
                  </tr>
                ))}
                {/*values.map(({name,color}) => (
                  <tr key={name}>
                    <td>{name}</td>
                    <td>{color} </td>
                    <td><button onClick={()=>removeEntry(name)}>X</button></td>
                  </tr>
                ))*/}
              </tbody>
            </table>

            {values !== null && (
              <button className="btn" onClick={()=>handleRefineClick(sqlSetName)}>
                Refine
              </button>
            )}
          </div>
        </div>
      
      {selectedCard !== null && (
        <div className="modal">
          <div className="modal-content">
            <button className="btn-cross" onClick={() => setSelectedCard(null)}>
              X
            </button>
            <h2>{result}</h2>
            <button
              className="btn"
              style={{
                width: "140px",
                height: "40px",
                margin: "20px 20px 20px 200px",
              }}
              onClick={() => setSelectedCard(null)}
            >
              OK
            </button>
          </div>
        </div>
      )}
      </div>
    </div>
  );
}

export default RefineCommunity;
