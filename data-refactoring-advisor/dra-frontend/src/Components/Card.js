// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import React, { useState } from "react";
import "../Css/styles.css";
const Card = ({ title, description, handleClick, isSelected }) => {
  const [isHovered, setIsHovered] = useState(false);

  const handleCardHover = () => {
    setIsHovered(!isHovered);
  };

  return (
    <div
      className={`card ${isSelected ? "selected" : ""}`}
      onClick={handleClick}
      onMouseEnter={handleCardHover}
      onMouseLeave={handleCardHover}
    >
      <br />
      <br />
      <h3>{title}</h3>
      <br />
      <br />
      <p>{description}</p>
      {isSelected && <div className="overlay" />}
    </div>
  );
};

export default Card;
