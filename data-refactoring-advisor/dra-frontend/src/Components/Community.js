// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import Pagination from "react-responsive-pagination";

function Community() {
  const [stsData, setStsData] = useState([]);
  const [refineCommunityButton, setRefineCommunityButton] = useState(null);
  const [refineCommunity, setRefineCommunity] = useState(null);
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
  var myHeaders = new Headers();
  myHeaders.append("Content-Type", "application/json");

  var requestOptions = {
    method: "GET",
    headers: myHeaders,
    redirect: "follow",
  };

  const handleCommunityDetectionClick = async (stsName) => {
    try {
      let viewGraphResponse = await fetch(
        `http://localhost:8080/api/communitydetection?sqlSetName=${stsName}`,
        requestOptions
      );

      let graphData = await viewGraphResponse.text();//{"test":"abc"}//
      navigate("/viewGraph", {state: {"graphData":graphData, "stsName":stsName, "actualGraphData":graphData}});

    } catch (error) {
      console.log("error", error);
    }
  };

  const handleViewCommunityClick = async (stsName) => {
    try {
      let viewGraphResponse = await fetch(
        `http://localhost:8080/api/viewcommunity?sqlSetName=${stsName}`,
        requestOptions
      );

      let graphData = await viewGraphResponse.text();
      navigate("/viewGraph", {state: {"graphData":graphData, "stsName":stsName}});
    } catch (error) {
      console.log("error", error);
    }
  };

  const handleRefineCommunityClick  = async (stsName) => {
    
    try {
      let refineCommunityResponse = await fetch(
        `http://localhost:8080/api/getRefineCommunityEdges?sqlSetName=${stsName}`,
        requestOptions
      );

      let refineCommunityData = await refineCommunityResponse.text();

      let viewGraphResponse = await fetch(
        `http://localhost:8080/api/viewcommunity?sqlSetName=${stsName}`,
        requestOptions
      );

      let graphData = await viewGraphResponse.text();

      navigate("/refine-community", 
              {state: {"refineCommunityData":refineCommunityData,
              "graphData":graphData,"stsName":stsName}});
    } catch (error) {
      console.log("error", error);
    }
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
       
        <button className="btn" onClick={() => handleCommunityDetectionClick(value)}>
         Community Detection
        </button>
        
        &emsp; &emsp; &emsp;
        <button className="btn-red" onClick={() => handleViewCommunityClick(value)}>
          View Community
        </button>
        
        &emsp; &emsp; &emsp;
        <button className="btn" onClick={() => handleRefineCommunityClick(value)}>
          Refine Community
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
        <h4>Community</h4>
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

export default Community;


// import React, { useState } from "react";
// import DetermineCommunity from "./DetermineCommunity";
// import { Link } from "react-router-dom";

// function Community() {
//   const data = [
//     { graphName: "Graph 1", stsName: "Tuning Set 1" },
//     { graphName: "Graph 2", stsName: "Tuning Set 1" },
//   ];

//   const [determineCommunity, setDetermineCommunity] = useState(null);
//   const [refineCommunity, setRefineCommunity] = useState(false);

//   const handleCommunityDetection = () => {
//       try {
//         var myHeaders = new Headers();
//         myHeaders.append("Content-Type", "application/json");
  
//         var requestOptions = {
//           method: "GET",
//           headers: myHeaders,
//           redirect: "follow",
//         };
  
//         let viewGraphResponse = await fetch(
//           `http://129.158.219.41:8080/api/viewgraph?sqlSetName=${stsName}`,
//           requestOptions
//         );
  
//         let graphData = await viewGraphResponse.text();
  
//         navigate("/viewGraph", { state: graphData });
//       } catch (error) {
//         console.log("error", error);
//       }
//     };

//   return (
//     <div className="form-container">
//       <div className="form">
//         <h4>Community</h4>
//         <br />
//         <br />
//         <br />
//         <table className="table">
//           <thead>
//             <tr className="tr">
//               <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
//                 Graph Name
//               </th>
//               <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
//                 STS Name
//               </th>
//               <th style={{ backgroundColor: "#41afca", color: "#f1f5f9" }}>
//                 Actions
//               </th>
//             </tr>
//           </thead>
//           <tbody>
//             {data.map((dra, index) => (
//               <tr key={index}>
//                 <td>{dra.graphName}</td>
//                 <td>{dra.stsName}</td>
//                 <td>
//                   <button className="btn" onClick={handleCommunityDetection}>
//                     Community Detection
//                   </button>
//                   &emsp; &emsp; &emsp;
//                   <button
//                     className="btn-red"
//                     onClick={() => setRefineCommunity(true)}
//                   >
//                     Refine Community
//                   </button>
//                 </td>
//               </tr>
//             ))}
//           </tbody>{" "}
//         </table>
//       </div>
//       {determineCommunity && (
//         <div className="modal">
//           <div className="modal-content auto">
//             <button
//               className="btn-cross"
//               onClick={() => setDetermineCommunity(null)}
//             >
//               X
//             </button>
//             <DetermineCommunity />
//           </div>
//         </div>
//       )}
//       {refineCommunity && (
//         <div>
//           <Link to="/refine-community">
//             <button
//               className="btn-cross"
//               onClick={() => setRefineCommunity(false)}
//             >
//               X
//             </button>
//           </Link>
//         </div>
//       )}
//     </div>
//   );
// }

// export default Community;
