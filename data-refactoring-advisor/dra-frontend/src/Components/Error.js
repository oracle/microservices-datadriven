// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import { Link } from "react-router-dom";
import "../Css/styles.css";

const Error = () => {
  return (
    <section className="form">
      <h2>404</h2>
      <p>page not found</p>
      <Link to="/">back home</Link>
    </section>
  );
};
export default Error;
