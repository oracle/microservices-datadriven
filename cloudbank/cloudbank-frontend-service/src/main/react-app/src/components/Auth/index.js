import React from "react";
import {useState} from "react";
import {dummyAuthProvider} from "./auth";
import AuthContext from "./context";

export const useAuth = () => {
    return React.useContext(AuthContext);
}

export default function AuthProvider(props) {
    let [user, setUser] = useState(null);

    let signIn = (userObject, callback) => {
        return dummyAuthProvider.signin( () => {
            setUser(userObject.username);
            callback();
        });
    }

    let signOut = (callback) => {
        return dummyAuthProvider.signout( () => {
            setUser(null);
            callback();
        })
    }

    let value = { user, signIn, signOut }
    return <AuthContext.Provider value={value}>{props.children}</AuthContext.Provider>
}

