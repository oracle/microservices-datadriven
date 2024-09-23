// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.service;

import com.example.dra.ViewGraphResponse;
import com.example.dra.bean.DatabaseDetails;

public interface GraphConstructorService {

    public String constructGraph(DatabaseDetails databaseDetails);

    public String populateDataInNodesTable(DatabaseDetails databaseDetails);

    public String populateDataInEdgesTable(DatabaseDetails databaseDetails);

    public String createHelperViewForAffinityCalculation(DatabaseDetails databaseDetails);

    public int createComputeAffinityProcedure(DatabaseDetails databaseDetails);

    ViewGraphResponse viewGraph(DatabaseDetails databaseDetails);

    boolean deleteGraph(DatabaseDetails databaseDetails);

    //public String executeProcedure(DatabaseDetails databaseDetails, String procedure);
}
