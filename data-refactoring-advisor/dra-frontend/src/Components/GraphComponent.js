// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import Pagination from "react-responsive-pagination";

function GraphComponent() {
  const [stsData, setStsData] = useState([]);
  const [deleteButton, setDeleteButton] = useState(null);

  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(6);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch(
          "http://localhost:8080/api/getsqltuningsetlist"
        );
        const result = await response.text();
        const parsedResult = JSON.parse(result);
        const sortedData = parsedResult.sort();
        setStsData(sortedData);
      } catch (error) {
        console.log("error", error);
      }
    };

    fetchData();
  }, []);
  const handleViewClick = async (stsName) => {
    try {
      var myHeaders = new Headers();
      myHeaders.append("Content-Type", "application/json");

      var requestOptions = {
        method: "GET",
        headers: myHeaders,
        redirect: "follow",
      };

      let viewGraphResponse = await fetch(
        `http://localhost:8080/api/viewgraph?sqlSetName=${stsName}`,
        requestOptions
      );

      let graphData = await viewGraphResponse.text();
      //console.log(graphData);
      navigate("/viewGraph", {state: {"graphData":graphData, "stsName":stsName}});
    } catch (error) {
      console.log("error", error);
    }
  };

  const handleDeleteClick = async (stsName) => {
    try {
      var myHeaders = new Headers();
      myHeaders.append("Content-Type", "application/json");

      var requestOptions = {
        method: "GET",
        headers: myHeaders,
        redirect: "follow",
      };

      let viewGraphResponse = await fetch(
        `http://localhost:8080/api/deletegraph?sqlSetName=${stsName}`,
        requestOptions
      );

      let result = await viewGraphResponse.text();
      console.log("result :: " + result);
      navigate("/graphs", result);
    } catch (error) {
      console.log("error", error);
    }
  };

  const handleDeleteClick1 = (event) => {
    event.preventDefault();
    setDeleteButton(true);
  };
  stsData.sort();
  // Pagination logic
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = stsData.slice(indexOfFirstItem, indexOfLastItem);

  const renderItems = currentItems.map((value, index) => (
    <tr key={index}>
      <td>{value}</td>
      <td>
        {/* <Link to="/viewGraph"> */}
        <button className="btn" onClick={() => handleViewClick(value)}>
          View Graph
        </button>
        {/* </Link> */}
        &emsp; &emsp; &emsp;
        <button className="btn-red" onClick={() => handleDeleteClick(value)}>
          Delete Graph
        </button>
      </td>
    </tr>
  ));

  const handlePageChange = (page) => {
    setCurrentPage(page);
  };

  // Calculate the range of page numbers to display
  const totalPages = Math.ceil(stsData.length / itemsPerPage);
  const displayRange = calculateDisplayRange(currentPage, totalPages);

  function calculateDisplayRange(currentPage, totalPages) {
    const displayRangeSize = 5; // Number of pagination numbers to display at a time
    let startPage = Math.max(1, currentPage - Math.floor(displayRangeSize / 2));
    let endPage = Math.min(startPage + displayRangeSize - 1, totalPages);

    // Adjust the startPage if the endPage is at the maximum limit
    startPage = Math.max(1, endPage - displayRangeSize + 1);

    const range = [];
    for (let i = startPage; i <= endPage; i++) {
      range.push(i);
    }
    return range;
  }

  return (
    <div className="form-container">
      <div className="form">
        <h4>Graphs</h4>
        <br />
        <br />
        <br />
        <table className="table">
          <thead>
            <tr>
              <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
                STS Name
              </th>
              <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
                Actions
              </th>
            </tr>
          </thead>
          <tbody>{renderItems}</tbody>
        </table>
        <div className="pagination-container">
          <Pagination
            current={currentPage}
            total={totalPages}
            onPageChange={handlePageChange}
          >
            {displayRange.map((pageNumber) => (
              <Pagination.Page
                key={pageNumber}
                page={pageNumber}
                active={pageNumber === currentPage}
                onClick={() => handlePageChange(pageNumber)}
              />
            ))}
          </Pagination>
        </div>
        <br />
      </div>
    </div>
  );
}

export default GraphComponent;
