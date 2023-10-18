// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import { Link, Outlet } from "react-router-dom";
import NavMenu from "./NavMenu";
const SharedLayout = () => {
  return (
    <>
      <NavMenu />
      <Outlet />
    </>
  );
};
export default SharedLayout;
