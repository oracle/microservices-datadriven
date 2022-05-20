import {useLocation, Navigate} from "react-router-dom";
import {useAuth} from "./index";

const Guard = (props) => {
    let auth = useAuth();
    let location = useLocation();

    if (!auth.user ) return <Navigate to={"/login"} state={{ from: location }} replace />;

    return props.children
}

export default Guard;