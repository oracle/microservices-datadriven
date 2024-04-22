import React from "react";
import {Link, useLocation, useNavigate} from "react-router-dom";
import {useAuth} from "../Auth";

function Modal() {
    //
    let auth = useAuth();
    let location = useLocation();
    let navigation = useNavigate();

    let from = location.state ? location.state.from.pathname : "/transfer";

    const submit = (event) => {
        // prevent reload
        event.preventDefault();

        let data = new FormData(event.currentTarget);
        let username = data.get("username");
        let password = data.get("password");

        auth.signIn({username: username, password: password}, () => {
            navigation(from, { replace: true })
        })
    }

    return (
        <div className={"modal flex flex-col"}>
            <div className={"modal-header"}>


            </div>
            <div className={"title flex flex-row flex-justify-center"}>
                <span>Login</span>
            </div>

            <form id={"app"} className={"form"} onSubmit={submit}>
                <div className={"fields flex flex-col"}>

                    <div className={"username field flex flex-col"}>
                        <label>Username</label>
                        <input type={"text"} id={"app-username"} className={"app-field"} name={"username"}
                               required={true} />
                    </div>

                    <div className={"password field flex flex-col"}>
                        <label>Password</label>
                        <input type={"password"} id={"app-password"} className={"app-field"} name={"password"}/>
                        <Link to={"/forgot"} className={"link login-link"}>Forgot username/password?</Link>
                    </div>
                </div>
                <div className={"actions flex flex-col"}>
                    <input type={"submit"} className={"submit signin app-button"} value={"Sign In"}/>
                    <Link to={"/signup"} className={"submit signup app-button"}>I don't have an account</Link>
                </div>
            </form>

        </div>

    )
}

export default Modal;