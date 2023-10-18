package com.example.dra.bean;

import com.example.dra.entity.RefineNodes;
import com.example.dra.entity.Nodes;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class DatabaseDetails {

    private String databaseName;
    private String hostname;
    private int port;
    private String username;
    private String password;
    private String url;
    private String sqlSetName;
    private String serviceName;
    private List<String> queries;
    private String graphData;
    private List<Nodes> refineNodesList;
    private List<RefineNodes> nodesList;

    private String oldSQLSetName;
    private String oldSchemaOwner;

    public DatabaseDetails() {

    }


    @Override
    public String toString() {
        return "DatabaseDetails{" +
                "sqlSetName='" + sqlSetName + '\'' +
                ", refineNodesList=" + refineNodesList +
                ", nodeList=" + nodesList +
                '}';
    }
}
