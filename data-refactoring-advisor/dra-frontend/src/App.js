// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import "./App.css";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Home from "./Components/Home";
import SharedLayout from "./Components/SharedLayout";
import GraphComponent from "./Components/GraphComponent";
import ConstructGraph from "./Components/ConstructGraph";
import Error from "./Components/Error";
import Community from "./Components/Community";
import ViewGraph from "./Components/ViewGraph";
import CreateSTS from "./Components/CreateSTS";
import FileUpload from "./Components/FileUpload";

import RefineCommunity from "./Components/RefineCommunity";

function App() {
  return (
    <div className="home-space">
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<SharedLayout />}>
            <Route index element={<Home />} />
            <Route path="create-sts" element={<CreateSTS />} />
            <Route path="construct-graph" element={<ConstructGraph />} />
            <Route path="graphs" element={<GraphComponent />} />
            <Route path="viewGraph" element={<ViewGraph />} />
            <Route path="community" element={<Community />} />
            <Route path="refine-community" element={<RefineCommunity />} />
            <Route path="fileupload" element={<FileUpload />} />
            <Route path="*" element={<Error />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </div>
  );
}

export default App;
