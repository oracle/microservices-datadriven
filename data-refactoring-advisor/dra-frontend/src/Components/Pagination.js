import React from "react";

const Pagination = ({ nPages, currentPage, setCurrentPage }) => {
  const pageNumbers = [...Array(nPages + 1).keys()].slice(1);

  const nextPage = () => {
    if (currentPage !== nPages) setCurrentPage(currentPage + 1);
  };
  const prevPage = () => {
    if (currentPage !== 1) setCurrentPage(currentPage - 1);
  };
  return (
    <nav>
      <ul className="pagination justify-content-center">
        <li>
          <a onClick={prevPage}>Previous</a>
        </li>
        {pageNumbers.map((pgNumber) => (
          <li
            key={pgNumber}
            className={`page-item ${
              currentPage === pgNumber ? " active" : ""
            } `}
          >
            <a onClick={() => setCurrentPage(pgNumber)}>{pgNumber}</a>
          </li>
        ))}
        <li>
          <a onClick={nextPage}>Next</a>
        </li>
      </ul>
    </nav>
  );
};

export default Pagination;
