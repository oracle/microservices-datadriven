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
