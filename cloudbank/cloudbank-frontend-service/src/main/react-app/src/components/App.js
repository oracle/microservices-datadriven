import './App.css';

import Header from "./Header";
import Login from "./Login";
import Transfer from "./Transfer";
import Footer from "./Footer";
import AuthProvider from "./Auth";
import AuthGuard from "./Auth/guard";

import React from "react";
import { Routes, Route } from "react-router-dom";

function App() {
  return (
      <AuthProvider>
          <div className={"root flex flex-col"}>
              <Header/>

              <Routes>
                  <Route path="/login" element={<Login />} />
                  <Route path="/transfer/*" element={<AuthGuard><Transfer /></AuthGuard>} />
                  <Route path="/" element={<AuthGuard><Transfer /></AuthGuard>} />
              </Routes>
              <Footer />
          </div>
      </AuthProvider>

  );
}

export default App;
