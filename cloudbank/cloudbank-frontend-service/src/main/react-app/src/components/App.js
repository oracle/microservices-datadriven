import './App.css';

import Header from "./Header";
import Transfer from "./Transfer";
import Footer from "./Footer";

import React from "react";
import { Routes, Route } from "react-router-dom";

function App() {
  return (
          <div className={"root flex flex-col"}>
              <Header/>

              <Routes>
                  <Route path="/transfer/*" element={<Transfer />} />
                  <Route path="/" element={<Transfer />} />
              </Routes>
              <Footer />
          </div>

  );
}

export default App;
