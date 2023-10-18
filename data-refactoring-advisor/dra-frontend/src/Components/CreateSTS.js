// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Link } from "react-router-dom";
import { LineWave } from "react-loader-spinner";

function CreateSTS() {
  const [databaseName, setDatabaseName] = useState("");
  const [userName, setUserName] = useState("");
  const [password, setPassword] = useState("");
  const [serviceName, setServiceName] = useState("");
  const [hostName, setHostName] = useState("");
  const [port, setPort] = useState("");
  const [sqlTuningSet, setSqlTuningSet] = useState("");
  const [selectedCard, setSelectedCard] = useState(null);
  const [result, setResult] = useState("");
  const [loading, setLoading] = useState(false);

  const navigate = useNavigate();

  const handleCollectSTSClick = async (event) => {
    event.preventDefault();
    
    var myHeaders = new Headers();
    myHeaders.append("Content-Type", "application/json");

    var raw = JSON.stringify({
      databaseName: databaseName,
      hostname: hostName,
      port: port,
      serviceName: serviceName,
      username: userName,
      password: password,
      sqlSetName: sqlTuningSet,
    });

    var requestOptions = {
      method: "POST",
      headers: myHeaders,
      body: raw,
      redirect: "follow",
    };

    /*let response = await fetch(
      "http://localhost:8080/api/collectsqltuningset",
      requestOptions
    );
        
    let data = await response.text();
    console.log(data);
    setSelectedCard(true);
    setResult(data);
    setSelectedCard(false);
    navigate("/graphs", data);*/
    setLoading(true);
    //alert("Started Collecting STS for : " + sqlTuningSet);
    
    await fetch(      
      "http://localhost:8080/api/collectsqltuningset",
      requestOptions
    ).then((response) => {
      setSelectedCard(true);
      if (response.ok) {
        const text = response.text();
        setResult("SQL Tuning Set is collected successfully for '"+sqlTuningSet+"'");
      } else {
        setResult("Error in Collecting STS for '"+sqlTuningSet+"'");
      }
      setSelectedCard(false);
    })
    /*.catch((error) => {
      console.error("Error in Collecting STS:", error);
      setSelectedCard(true);
      setResult(error);
      setSelectedCard(false);
    })*/
    ;
    setLoading(false);
    //navigate("/graphs", []);
    //   .then((response) => response.text())
    //   .then((response) => console.log("Collecting the STS"))
    //   .catch((error) => console.log("error", error));
    
    //console.log(response)
    //let data = await response.text();
    //alert("In Frontend - Collecting STS for : " + sqlTuningSet);
    //console.log(data);
    //setResult("In Frontend - Collecting STS for : " + sqlTuningSet);
    //navigate("/graphs", data);*/
  };

  return (
    <div className="form-container">
      <div className="form">
        <form onSubmit={(e) => handleCollectSTSClick(e)}>
          <div><h4>Collect SQL Tuning Set</h4></div>
          
          <Link to="/load-sts">
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
          <div className="form-row">
            <label htmlFor="hostName" className="form-label">
              Hostname:
            </label>
            <input
              type="text"
              className="form-input"
              id="hostName"
              required
              value={hostName}
              onChange={(e) => setHostName(e.target.value)}
            />
          </div>

          <div className="form-row">
            <label htmlFor="databaseName" className="form-label">
              Database name:
            </label>
            <input
              type="text"
              className="form-input"
              id="databaseName"
              value={databaseName}
              required
              onChange={(e) => setDatabaseName(e.target.value)}
            />
          </div>

          <div className="form-row">
            <label htmlFor="port" className="form-label">
              Port:
            </label>
            <input
              type="number"
              className="form-input"
              id="port"
              value={port}
              required
              onChange={(e) => setPort(e.target.value)}
            />
          </div>
          <div className="form-row">
            <label htmlFor="serviceName" className="form-label">
              Service Name:
            </label>
            <input
              type="text"
              className="form-input"
              id="serviceName"
              required
              value={serviceName}
              onChange={(e) => setServiceName(e.target.value)}
            />
          </div>

          <div className="form-row">
            <label htmlFor="userName" className="form-label">
              Username:
            </label>
            <input
              type="text"
              className="form-input"
              id="userName"
              required
              value={userName}
              onChange={(e) => setUserName(e.target.value)}
            />
          </div>

          <div className="form-row">
            <label htmlFor="password" className="form-label">
              Password:
            </label>
            <input
              type="text"
              className="form-input"
              id="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          <div className="form-row">
            <label htmlFor="sqlTuningSet" className="form-label">
              SQL Tuning Set Name:
            </label>
            <input
              type="text"
              className="form-input"
              id="sqlTuningSet"
              required
              value={sqlTuningSet}
              onChange={(e) => setSqlTuningSet(e.target.value)}
            />
          </div>
          </div>
          <br />
          <button type="submit" className="btn btn-block">
            Collect SQL Tuning Set
          </button>
          <br />
        </form>
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
  );
}

export default CreateSTS;
