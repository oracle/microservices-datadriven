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
