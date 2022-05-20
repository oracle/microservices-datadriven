import {Link, useLocation} from "react-router-dom";
import "./index.css";


const Component = function(props) {

    let location = useLocation();

    let isCurrent = (pathname) => {
        return location.pathname === pathname ? " current " : "";
    }


    return (
        <div className={"container flex flex-row flex-justify-space-between transfer-header"}>
            <div className={"left flex flex-row"}>
                <Link to={"/transfer"} className={"nav app-button transfer" + isCurrent("/transfer") + isCurrent("/")}>Make Transfer</Link>
                <Link to={"/transfer/history"} className={"nav app-button " + isCurrent("/transfer/history")}>View Transfer History</Link>
            </div>
        </div>
    )
}
export default Component;