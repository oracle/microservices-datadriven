// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import React, { useState } from "react";
import { Link } from "react-router-dom";
//import { Link, useNavigate } from "react-router-dom";
import "../Css/styles.css";
import { useLocation } from "react-router-dom";
import Pagination from "react-responsive-pagination";

function RefineCommunity() {
  const [values, setValues] = useState([]);
  const [source, setSource] = useState("");
  const [sources, setSources] = useState([]);
  const [destination, setDestination] = useState("");
  const [destinations, setDestinations] = useState([]);
  const [affinity, setAffinity] = useState("");
  const [selectedCard, setSelectedCard] = useState(null);
  const location = useLocation();
  let refineCommunityData =  JSON.parse(location.state.refineCommunityData);

  const sources1 = [...new Set(refineCommunityData.map((item) => item.source))];
  setSources(sources1)
  //console.log("sources :: " + sources);
  //debugger

  const handleCountry = (event) => {
    console.log("In handleCountry :: " + event)
    /*let destinations = refineCommunityData.filter((state) => state.source === value);
    console.log("Selected Dest1 :: " + destinations)
    destinations = [...new Set(destinations.map((item) => item.destinations))];
    console.log("Selected Dest2 :: " + destinations)
    setDestinations(destinations);*/
  };

  //createMap();
  //const [refineCommunityData, setRefineCommunityData] = useState("");
  let sqlSetName = location.state.stsName;
  console.log("Source :: " + refineCommunityData);
  const handleAdd = () => {
    const newValues = [...values];
    newValues.push({ source, destination, affinity });
    setValues(newValues);
    setSource("");
    setDestination("");
    setAffinity("");
  };
  const [myMap, setMyMap] = useState(new Map());

  const createMap = () => {
    refineCommunityData.map(item => (
      console.log(item.source)
    ));
  };
  const handleSourceChange = (event) => {
    setSource(event.target.value);    
  };

  const handleDestinationChange = (event) => {
    setDestination(event.target.value);
  };

  const handleAffinityChange = (event) => {
    setAffinity(event.target.value);
  };

  

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
              
              
              <select className="form-input" id="source"
                placeholder="Select the Source Entity:"
                value="Source Label"
                options={sources}
                onChange={(e) => handleCountry(e.source)}
                getOptionLabel={x => x.source}
                getOptionValue={x => x.source}
              />
            </div>
            <div className="form-row">
              <label htmlFor="destination" className="form-label">
                Select the Destination Entity:
              </label>
              <select
                placeholder="Select Language"
                value={lang}
                options={langList}
                onChange={handleLanguageChange}
                getOptionLabel={x => x.name}
                getOptionValue={x => x.code}
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
              <button type="submit" className="btn" onClick={handleAdd}>
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
                {values.map((value, index) => (
                  <tr key={index}>
                    <td>{value.source}</td>
                    <td>{value.destination} </td>
                    <td>{value.affinity}</td>
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
