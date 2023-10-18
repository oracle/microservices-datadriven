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
