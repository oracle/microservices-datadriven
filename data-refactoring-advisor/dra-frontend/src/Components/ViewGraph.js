// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import React, { useState, useEffect, useRef } from "react";
import * as d3 from "d3";
import "../Css/styles.css";
import { Link, useNavigate } from "react-router-dom";
import { useLocation } from "react-router-dom";

function ViewGraph() {
  const svgRef = useRef();
  const navigate = useNavigate();
  const location = useLocation();
  let graphData = JSON.parse(location.state.graphData);
  let sqlSetName = location.state.stsName;
  
  const handleClick = () => {
    navigate("/graphs");
  };

  const handleSaveClick = async (sqlSetName, graphData) => {
    console.log("--------------------------------------------")
    console.log("In handleSaveClick, sqlSetName : "+sqlSetName);
    console.log("In handleSaveClick, graphData : "+graphData);
    try {
      var myHeaders = new Headers();
      myHeaders.append("Content-Type", "application/json");

      var raw = JSON.stringify({
        sqlSetName: sqlSetName,
        graphData: {graphData},
      });
      console.log("Saving raw Data :: " + raw);
      var requestOptions = {
        method: "POST",
        headers: myHeaders,
        body: raw,
        redirect: "follow",
      };

      let response = await fetch(
        "http://localhost:8080/api/savecommunity",
        requestOptions
      );
      
      let data = await response.text();
      console.log(data);
      //setResult(data);
    } catch (error) {
      console.log("error", error);
    }
  };

  useEffect(() => {
    const svg = d3.select(svgRef.current);
    if (graphData) {
      console.log("In ViewGraph :", graphData);
      const nodes = Object.values(graphData.nodes);
      const edges = Object.values(graphData.edges);

      console.log("nodes:", nodes);
      console.log("edges:", edges);

      // Calculate the dimensions based on the form-container and form class names
      const containerWidth = document.querySelector(".form-container").offsetWidth;
      const containerHeight = document.querySelector(".form-container").offsetHeight;
      const formWidth = document.querySelector(".form").offsetWidth;
      const formHeight = document.querySelector(".form").offsetHeight;
      console.log("containerWidth = "+ containerWidth);
      console.log("containerHeight = "+ containerHeight);
      console.log("formWidth = "+ formWidth);
      console.log("formHeight = "+ formHeight);
      const svgWidth = Math.min(containerWidth, formWidth);
      const svgHeight = Math.min(containerHeight, formHeight);

      // Clear the SVG element
      svg.selectAll("*").remove();

      // Create the force simulation
      const simulation = d3
        .forceSimulation(nodes)
        .force(
          "link",
          d3
            .forceLink(edges)
            .id((d) => d.name)
            .distance(150)
            .strength(1)
        )
        .force("charge", d3.forceManyBody().strength(-100))
        .force("center", d3.forceCenter(svgWidth / 2, svgHeight / 2));

      svg.attr("width", svgWidth).attr("height", svgHeight);

      // Create the edges
      const link = svg
        .append("g")
        .selectAll("line")
        .data(edges)
        .join("line")
        .attr("stroke", "black")
        .attr("stroke-opacity", 0.6)
        .attr("stroke-width", (d) => Math.sqrt(d.weight * 10));

      // Create the nodes
      const node = svg
        .append("g")
        .selectAll("circle")
        .data(nodes)
        .join("circle")
        .attr("r", 10)
        .attr("fill", (d) => d.color)
        .call(drag(simulation));

      // Add labels to the nodes
      const label = svg
        .append("g")
        .selectAll("text")
        .data(nodes)
        .join("text")
        .text((d) => d.name)
        .style("font-size", "12px")
        .style("pointer-events", "none");

      // Define the drag behavior
      function drag(simulation) {
        function dragstarted(event) {
          if (!event.active) simulation.alphaTarget(0.9).restart();
          event.subject.fx = event.subject.x;
          event.subject.fy = event.subject.y;
        }
        function dragged(event) {
          event.subject.fx = event.x;
          event.subject.fy = event.y;
        }

        function dragended(event) {
          if (!event.active) simulation.alphaTarget(0);
          event.subject.fx = null;
          event.subject.fy = null;
        }

        return d3
          .drag()
          .on("start", dragstarted)
          .on("drag", dragged)
          .on("end", dragended);
      }

      // Define the tick function
      function tick() {
        link
          .attr("x1", (d) => d.source.x)
          .attr("y1", (d) => d.source.y)
          .attr("x2", (d) => d.target.x)
          .attr("y2", (d) => d.target.y);

        node.attr("cx", (d) => d.x).attr("cy", (d) => d.y);
        label.attr("x", (d) => d.x + 15).attr("y", (d) => d.y - 10);
      }

      // Set up the simulation event listeners
      simulation.on("tick", tick);

      // Clean up the simulation when the component unmounts
      return () => simulation.stop();
    }
  }, [graphData]);

  var groupBy = function(xs, key) {
    return xs.reduce(function(rv, x) {
      (rv[x[key]] = rv[x[key]] || []).push(x);
      return rv;
    }, {});
  };

  const Circle = ({ color }) => {
    const circleStyle = {
      fill: color,
    };
  
    return (
      <svg height="50" width="50">
        <circle cx="20" cy="20" r="20" style={circleStyle} />
      </svg>
    );
  };

  var renderDataVar = function () {
    const data = groupBy(graphData.nodes, 'color');
    return Object.keys(data).map(objKey => 
      <tr key={objKey}> 
        <td><Circle color={objKey} /></td>
        <td>{data[objKey].map((item,index) => (index===0 ? item.name : ", " +item.name))}</td>
      </tr>
 )};

 const renderItems = renderDataVar();

 return (
    <div className="form-container">  
      
      <div className="form">
      <div><h4>SQL Tuning Set : {sqlSetName}</h4></div>
      <br/>
      <br/>
        <table className="table">
          <thead>
            <tr>
              <th style={{ backgroundColor: "#41afca", color: "#f1f5f9",width: "20%" }}>
                Community Color
              </th>
              
              <th style={{ backgroundColor: "#41afca", color: "#f1f5f9", width: "90%" }}>
                Nodes
              </th>
            </tr>
          </thead>
          <tbody>{renderItems}</tbody>
        </table>
        <Link to="/graphs">
          <button className="btn-cross btn-cross-form" onClick={handleClick}>
            X
          </button>
        { /* <button className="btn" onClick={() => handleSaveClick(sqlSetName, graphData)}>
            Save 
  </button>*/}
        </Link>

        <svg ref={svgRef} width={750} height={500}></svg>
        <Link to="/graphs">
        <div>
          {/*<button className="btn_right" onClick={() => handleSaveClick(sqlSetName,graphData)}>
            Save 
</button>*/}
        </div>
        <div>
        </div>
        </Link>
        
      </div>

      
        

    </div>
  );
}

export default ViewGraph;
