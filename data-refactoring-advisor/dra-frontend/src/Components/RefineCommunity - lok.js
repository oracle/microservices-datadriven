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

  const [affinity, setAffinity] = "";
  const [selectedCard, setSelectedCard] = "";
  const location = useLocation();
  let refineCommunityData =  JSON.parse(location.state.refineCommunityData);

  useEffect(() => {
    fetchSources();
  }, []);
  
  console.log("sources :: " + sources);
  //debugger

  function fetchSources() {
    const sources1 = [...new Set(refineCommunityData.map((item) => item.source))];
    setSources(sources1)
  }

  function handleSourceChange (obj) {
    //obj.target.value
    setSource(obj.source);
    //const destinations = refineCommunityData.filter((item) => item.source === obj.target.value);
    //const selectedDestinations = obj.destinations.map((itemDest) => itemDest.table2);
    
    setDestinations(obj.destinations);
    setDestination(null);
  };
  
  // handle change event of the destination dropdown
  const handleDestinationChange = (obj) => {
    debugger
    setDestination(obj);

  };

 /* const handleCountry = (event) => {
    console.log("In handleCountry :: " + event)
    let destinations = refineCommunityData.filter((state) => state.source === value);
    console.log("Selected Dest1 :: " + destinations)
    destinations = [...new Set(destinations.map((item) => item.destinations))];
    console.log("Selected Dest2 :: " + destinations)
    setDestinations(destinations);
  };*/

  //createMap();
  //const [refineCommunityData, setRefineCommunityData] = useState("");
  let sqlSetName = location.state.stsName;
  //console.log("Source :: " + refineCommunityData);
  const handleAdd = () => {
    const newValues = [...values];
    newValues.push({ source, destination, affinity });
    setValues(newValues);
    setSource("");
    setDestination("");
    setAffinity("");
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
              <Select className="form-input" id="source"
                placeholder="Select the Source Entity:"
                value={source}
                options={sources}
                onChange={(e) => handleSourceChange(e)}
                getOptionLabel={x => x.source}
                getOptionValue={x => x.source}
              />
            </div>
            <div className="form-row">
              <Select
                placeholder="Select the Destination Entity"
                value={destination}
                options={destinations}
                onChange={(e) => handleDestinationChange(e)}
                getOptionLabel={x => x.table2}
                getOptionValue={x => x.affinity}
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
