import TransferNav from "./nav";
import History from "./history";
import Transfer from "./transfer";
import Login from "../Login";

import {Route, Routes} from "react-router-dom";
import React, {useState} from "react";

function Component() {

    return (
        <section className={"transfer app-section flex-grow-8"}>
            <TransferNav/>
            <Routes>
                <Route path="/history" element={<History />} />
                <Route path="/" element={<Transfer/>} />

            </Routes>

        </section>
    )
}

export default Component;