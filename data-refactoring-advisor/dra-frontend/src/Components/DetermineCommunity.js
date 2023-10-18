// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import React, { useState, useEffect, useRef } from "react";
import * as d3 from "d3";
import "../Css/styles.css";
import { Link } from "react-router-dom";

function DetermineCommunity() {
  const svgRef = useRef();
  const [isClicked, setIsClicked] = useState(false);

  const handleClick = () => {
    setIsClicked(true);
  };

  useEffect(() => {
    const svg = d3.select(svgRef.current);

    // Define the data for the nodes and links
    const nodes = [
      { id: "A", color: "red" },
      { id: "B", color: "pink" },
      { id: "C", color: "blue" },
      { id: "D", color: "grey" },
      { id: "E", color: "pink" },
    ];

    const links = [
      { source: "A", target: "B", weight: 1 },
      { source: "B", target: "A", weight: 1 },
      { source: "A", target: "C", weight: 2 },
      { source: "A", target: "E", weight: 4 },
      { source: "A", target: "D", weight: 5 },
    ];

    // Create the force simulation
    const simulation = d3
      .forceSimulation(nodes)
      .force(
        "link",
        d3
          .forceLink(links)
          .id((d) => d.id)
          .distance(100)
      )
      .force("charge", d3.forceManyBody().strength(-50))
      .force("center", d3.forceCenter(300, 150));

    // Create the links
    const link = svg
      .selectAll(".link")
      .data(links)
      .enter()
      .append("line")
      .attr("class", "link")
      .attr("stroke", "black")
      .attr("marker-end", "url(#arrowhead)");

    // Add weight labels to the links
    const weightLabel = svg
      .selectAll(".weight-label")
      .data(links)
      .enter()
      .append("text")
      .attr("class", "weight-label")
      .attr("text-anchor", "middle")
      .attr("dy", "-0.5em")
      .text((d) => d.weight);

    // Create the nodes
    const node = svg
      .selectAll(".node")
      .data(nodes)
      .enter()
      .append("circle")
      .attr("class", "node")
      .attr("r", 15)
      .attr("fill", (d) => d.color);

    // Add labels to the nodes
    const label = svg
      .selectAll(".label")
      .data(nodes)
      .enter()
      .append("text")
      .attr("class", "label")
      .attr("text-anchor", "middle")
      .attr("dy", ".35em")
      .text((d) => d.id);

    // Add the arrowhead marker to the svg
    svg
      .append("defs")
      .selectAll("marker")
      .data(["arrowhead"])
      .enter()
      .append("marker")
      .attr("id", "arrowhead")
      .attr("viewBox", "0 -5 10 10")
      .attr("refX", 20)
      .attr("markerWidth", 8)
      .attr("markerHeight", 8)
      .attr("orient", "auto")
      .append("path")
      .attr("d", "M0,-5L10,0L0,5");

    // Add arrowhead marker to the svg
    svg
      .append("defs")
      .selectAll("marker")
      .data(["arrowhead"])
      .enter()
      .append("marker")
      .attr("id", "arrowhead")
      .attr("viewBox", "0 -5 10 10")
      .attr("refX", 25)
      .attr("markerWidth", 8)
      .attr("markerHeight", 8)
      .attr("orient", "auto")
      .append("path")
      .attr("d", "M0,-5L10,0L0,5");

    // Add the text for weight to the edges
    const text = svg
      .selectAll(".text")
      .data(links)
      .enter()
      .append("text")
      .attr("class", "text")
      .text((d) => d.weight);

    // Update the position of the text on each tick
    simulation.on("tick", () => {
      link
        .attr("x1", (d) => d.source.x)
        .attr("y1", (d) => d.source.y)
        .attr("x2", (d) => d.target.x)
        .attr("y2", (d) => d.target.y);

      node.attr("cx", (d) => d.x).attr("cy", (d) => d.y);

      label.attr("x", (d) => d.x).attr("y", (d) => d.y);

      text
        .attr("x", (d) => (d.source.x + d.target.x) / 2)
        .attr("y", (d) => (d.source.y + d.target.y) / 2);
    });
  }, []);

  return (
    <div>
      <svg ref={svgRef} width="400" height="258"></svg>
      {/* <div>
        <Link to="/graphs">
          <button className="btn" onClick={handleClick}>
            OK
          </button>
        </Link>
      </div> */}
    </div>
  );
}

export default DetermineCommunity;
