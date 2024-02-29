// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.service.impl;

import com.example.dra.ViewGraphResponse;
import com.example.dra.bean.DatabaseDetails;
import com.example.dra.communitydetection.InfomapGraphClient;
import com.example.dra.dto.EdgeDto;
import com.example.dra.dto.RefineCommunityDto;
import com.example.dra.entity.Edges;
import com.example.dra.entity.GraphData;
import com.example.dra.entity.Nodes;
import com.example.dra.entity.RefineNodes;
import com.example.dra.service.CommunityDetectionService;


import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.json.JSONArray;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class CommunityDetectionServiceImpl implements CommunityDetectionService {

    @Autowired
    GraphConstructorServiceImpl graphConstructorServiceImpl;
    @Value("${spring.datasource.hostname}")
    String hostname;
    @Value("${spring.datasource.port}")
    String port;
    @Value("${spring.datasource.service.name}")
    String serviceName;
    @Value("${spring.datasource.username}")
    String username;
    @Value("${spring.datasource.password}")
    String password;

    @Autowired
    DRAUtilsImpl draUtilsImpl;

    @Override
    public ViewGraphResponse communityDetection(DatabaseDetails databaseDetails) {
        databaseDetails = draUtilsImpl.setDatabaseDetails(databaseDetails);
        System.out.println("-----------------------------------------------");
        System.out.println("Input Details of VIEW GRAPH API ");
        String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
        System.out.println("Username :: "+ databaseDetails.getUsername());
        System.out.println("SQL Tuning Set :: "+ databaseDetails.getSqlSetName());
        System.out.println("-----------------------------------------------");

        Connection connection = null;
        List<Edges> edges = new ArrayList<>();
        ViewGraphResponse viewGraphResponse = null;
        try {
            
            createTableViewsForSTS(databaseDetails);
            
            viewGraphResponse = new InfomapGraphClient().createGraph(databaseDetails.getSqlSetName());

            dropTableViewForSTS(databaseDetails);

            String getEdgesQuery = "SELECT * FROM "+databaseDetails.getUsername()+".EDGES WHERE TABLE_SET_NAME = ?";
            System.out.println("getEdgesQuery :: " + getEdgesQuery);

            connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
            PreparedStatement statement = connection.prepareStatement(getEdgesQuery);
            statement.setString(1, databaseDetails.getSqlSetName());

            ResultSet resultSet = statement.executeQuery();

            Edges edge;
            while (resultSet.next()) {
                edge = new Edges();
                edge.setSource(resultSet.getString("TABLE1"));
                edge.setTarget(resultSet.getString("TABLE2"));
                edge.setWeight(resultSet.getDouble("TOTAL_AFFINITY"));
                edges.add(edge);
            }
            viewGraphResponse.setEdges(edges);

            ObjectMapper Obj = new ObjectMapper();
            try {
                String jsonStr = Obj.writeValueAsString(viewGraphResponse);
                System.out.println(":: viewGraphResponse JSON to Save :: " + jsonStr);
                databaseDetails.setGraphData(jsonStr);
                saveCommunity(databaseDetails);
            } catch (JsonProcessingException e) {
                throw new RuntimeException(e);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        catch (ExecutionException e) {
            throw new RuntimeException(e);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        }
        System.out.println("Community Detection is Completed for : " + databaseDetails.getSqlSetName());
        return viewGraphResponse;
    }

    private void createTableViewsForSTS(DatabaseDetails databaseDetails) {
        String nodesTableViewName = "NODES_VIEW_"+databaseDetails.getSqlSetName();
        String edgesTableViewName = "EDGES_VIEW_"+databaseDetails.getSqlSetName();

        System.out.println("Creating Nodes Table View = " + databaseDetails.getSqlSetName());
        String createNodesTableViewQueryStr = "CREATE OR REPLACE VIEW "+nodesTableViewName+" AS SELECT * FROM NODES WHERE TABLE_SET_NAME = '"+databaseDetails.getSqlSetName()+"'";
        graphConstructorServiceImpl.executeUpdateSQLQuery(databaseDetails, createNodesTableViewQueryStr);

        System.out.println("Altering Nodes Table View = " + databaseDetails.getSqlSetName());
        String alterNodesTableViewQueryStr = "ALTER VIEW "+nodesTableViewName+" ADD CONSTRAINT "+nodesTableViewName+"_PK PRIMARY KEY (ID) DISABLE NOVALIDATE";
        graphConstructorServiceImpl.executeUpdateSQLQuery(databaseDetails, alterNodesTableViewQueryStr);

        System.out.println("Creating Edges Table View = " + databaseDetails.getSqlSetName());
        String createEdgesTableViewQueryStr = "CREATE OR REPLACE VIEW EDGES_VIEW_"+databaseDetails.getSqlSetName()+" AS SELECT * FROM EDGES WHERE TABLE_SET_NAME = '"+databaseDetails.getSqlSetName()+"'";
        graphConstructorServiceImpl.executeUpdateSQLQuery(databaseDetails, createEdgesTableViewQueryStr);

        System.out.println("Altering Edges Table View = " + databaseDetails.getSqlSetName());
        String alterEdgesTableViewQueryStr = "ALTER VIEW "+edgesTableViewName+" ADD CONSTRAINT "+edgesTableViewName+"_PK PRIMARY KEY (ID) DISABLE NOVALIDATE";
        graphConstructorServiceImpl.executeUpdateSQLQuery(databaseDetails, alterEdgesTableViewQueryStr);

    }

    private void dropTableViewForSTS(DatabaseDetails databaseDetails) {
        System.out.println("Dropping Nodes Table View = " + databaseDetails.getSqlSetName());
        String dropNodesTableViewQueryStr = "DROP VIEW NODES_VIEW_"+databaseDetails.getSqlSetName();
        graphConstructorServiceImpl.executeUpdateSQLQuery(databaseDetails, dropNodesTableViewQueryStr);

        System.out.println("Dropping Edges Table View = " + databaseDetails.getSqlSetName());
        String dropEdgesTableViewQueryStr = "DROP VIEW EDGES_VIEW_"+databaseDetails.getSqlSetName();
        graphConstructorServiceImpl.executeUpdateSQLQuery(databaseDetails, dropEdgesTableViewQueryStr);
    }


    @Override
    public String viewCommunity(DatabaseDetails databaseDetails) {
        databaseDetails = draUtilsImpl.setDatabaseDetails(databaseDetails);
        System.out.println("-----------------------------------------------");
        System.out.println("Input Details of VIEW COMMUNITY API ");
        String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
        System.out.println("STS :: "+ databaseDetails.getSqlSetName());
        System.out.println("-----------------------------------------------");
        String getGraphDataQuery = "SELECT GRAPH_DATA_JSON FROM GRAPHS_DATA WHERE TABLE_SET_NAME = ?";
        Connection connection = null;
        String graphDataJson = "";
        try {
            // Establishing a connection to the database
            connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());

            PreparedStatement statement = connection.prepareStatement(getGraphDataQuery);
            statement.setString(1, databaseDetails.getSqlSetName());

            //Statement s = connection.createStatement();
            ResultSet resultSet = statement.executeQuery();
            if (resultSet.next()) {
                // Retrieve column values from the current row
                graphDataJson = resultSet.getString("GRAPH_DATA_JSON");
            }
            System.out.println("graphDataJson :: " + graphDataJson);
        } catch (SQLException e) {
            System.out.println("SQLException, Error Code :: " + e.getErrorCode());
            e.printStackTrace();
        } finally {
            // Closing the resources
            try {
                if (connection != null) {
                    connection.close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }

        return graphDataJson;
    }

    @Override
    public String saveCommunity(DatabaseDetails databaseDetails) {
        databaseDetails = draUtilsImpl.setDatabaseDetails(databaseDetails);
        System.out.println("-----------------------------------------------");
        System.out.println("Input Details of SAVE COMMUNITY API");
        String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
        System.out.println("JSON DATA :: "+ databaseDetails.getGraphData());
        System.out.println("-----------------------------------------------");
        Connection connection = null;
        String result;
        try {
            connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
            boolean isCommunitiesExistForSQLTuningSet = isCommunitiesExistForSQLTuningSet(databaseDetails);
            PreparedStatement statement;
            if (isCommunitiesExistForSQLTuningSet) {
                // Update Query
                String updateQuery = "UPDATE GRAPHS_DATA SET GRAPH_DATA_JSON = ? WHERE TABLE_SET_NAME = ?";
                statement = connection.prepareStatement(updateQuery);
                // Set values for the parameters
                statement.setString(1, databaseDetails.getGraphData().toString());
                statement.setString(2, databaseDetails.getSqlSetName());

                System.out.println("Updating the Graph Data for STS :: " + databaseDetails.getSqlSetName());
                int rowsUpdated = statement.executeUpdate();
                if (rowsUpdated > 0) {
                    result = "Row Updated successfully.";
                } else {
                    result = "Failed to Update row.";
                }
            } else {
                // Prepare the INSERT statement
                String insertQuery = "INSERT INTO GRAPHS_DATA (TABLE_SET_NAME,GRAPH_DATA_JSON) VALUES (?, ?)";
                statement = connection.prepareStatement(insertQuery);
                // Set values for the parameters
                statement.setString(1, databaseDetails.getSqlSetName());
                statement.setString(2, databaseDetails.getGraphData().toString());

                // Execute the INSERT statement
                System.out.println("Inserting the Graph Data for STS :: " + databaseDetails.getSqlSetName());
                int rowsInserted = statement.executeUpdate();
                if (rowsInserted > 0) {
                    result = "Row inserted successfully.";
                } else {
                    result = "Failed to insert row.";
                }
            }
            // Close resources
            statement.close();
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            // Closing the resources
            try {
                if (connection != null) {
                    connection.close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        return "Saved Community Data : " + databaseDetails.getGraphData() ;
    }

    private boolean isCommunitiesExistForSQLTuningSet(DatabaseDetails databaseDetails) {
        String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
        Connection connection = null;
        boolean result = false;
        try {
            connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
            String query = "SELECT COUNT(1) AS RESULT_COUNT FROM GRAPHS_DATA WHERE TABLE_SET_NAME = ?";
            PreparedStatement statement = connection.prepareStatement(query);

            // Set values for the parameters
            statement.setString(1, databaseDetails.getSqlSetName());
            //Statement s = connection.createStatement();
            ResultSet resultSet = statement.executeQuery();
            if (resultSet.next()) {
                // Retrieve column values from the current row
                int count = resultSet.getInt("RESULT_COUNT");
                System.out.println("No of rows in GRAPHS_DATA table for " + databaseDetails.getSqlSetName() + " = " + count);
                if (count > 0) {
                    result = true;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            // Closing the resources
            try {
                if (connection != null) {
                    connection.close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        return result;
    }

        @Override
    public List<RefineCommunityDto> getRefineCommunityEdges(DatabaseDetails databaseDetails) {
        databaseDetails = draUtilsImpl.setDatabaseDetails(databaseDetails);
        System.out.println("-----------------------------------------------");
        System.out.println("Input Details of GET REFINE COMMUNITY EDGES API ");
        String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
        System.out.println("DB Connection String :: "+dbUrlConnectionStr);
        System.out.println("STS :: "+ databaseDetails.getSqlSetName());
        System.out.println("-----------------------------------------------");
        String getEdgesQuery = "SELECT TABLE1, '['|| (LISTAGG(('{\"table2\":\"' ||  TABLE2 || '\", \"total_affinity\":' || TO_CHAR(TOTAL_AFFINITY,'FM999990D99999') || '}'),', ') WITHIN GROUP (ORDER BY TABLE1)) || ']'  AS DESTINATION_TABLES FROM EDGES WHERE TABLE_SET_NAME = ? GROUP BY TABLE1";
        Connection connection = null;
        List<RefineCommunityDto> refineCommunityDtos = new ArrayList<>();

        try {
            // Establishing a connection to the database
            connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
            PreparedStatement statement = connection.prepareStatement(getEdgesQuery);

            // Set values for the parameters
            statement.setString(1, databaseDetails.getSqlSetName());

            //Statement statement = connection.createStatement();
            ResultSet resultSet = statement.executeQuery();
            RefineCommunityDto refineCommunityDto;
            String source;
            String destination;
            while (resultSet.next()) {
                // Retrieve column values from the current row
                source = resultSet.getString("TABLE1");
                destination =  resultSet.getString("DESTINATION_TABLES");
                System.out.println("destination :: " + destination);
                refineCommunityDto = new RefineCommunityDto();
                refineCommunityDto.setSource(source);
                JSONArray jsonArray = new JSONArray(destination);
                ObjectMapper objMapper = new ObjectMapper();
                List<EdgeDto> edgeDtos = new ArrayList<>();
                EdgeDto edgeDto;
                for (int i=0;i<jsonArray.length();i++){
                    edgeDto = new EdgeDto();
                    //Adding each element of JSON array into ArrayList
                    JSONObject jsonObj = (JSONObject) jsonArray.get(i);
                    edgeDto.setTable2(jsonObj.getString("table2"));
                    edgeDto.setTotal_affinity(jsonObj.getDouble("total_affinity"));
                    edgeDtos.add(edgeDto);
                }
                refineCommunityDto.setDestinations(edgeDtos);
                refineCommunityDtos.add(refineCommunityDto);
            }

            String graphDataJson = viewCommunity(databaseDetails);


        } catch (SQLException e) {
            System.out.println("SQLException, Error Code :: " + e.getErrorCode());
            e.printStackTrace();
        } finally {
            // Closing the resources
            try {
                if (connection != null) {
                    connection.close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        return refineCommunityDtos;
    }

    @Override
    public String refineCommunityUsingColors(DatabaseDetails databaseDetails) {
        System.out.println("In refineCommunity() : " + databaseDetails.getRefineNodesList().size());
        for (Nodes node : databaseDetails.getRefineNodesList()) {
            System.out.println("-----------------------------------");
            System.out.println("Node Name : " + node.getName());
            System.out.println("Node color : " + node.getColor());
            // Get Nodes of destination community
            List<String> nodesOfDestCommunity = getNodesOfDestCommunity(databaseDetails,node);
            System.out.println("nodesOfDestCommunity : " + nodesOfDestCommunity);

            // Get Edges between Source Nodes and the Nodes of Destination Community
            // and Update the affinity to 1
            //int numOfRowsUpdated = updateAffinityOfEdgesBtwSrcAndDestCommunity(databaseDetails,node, nodesOfDestCommunity);

            List<Integer> ids = getIdsOfMatchedEdges(databaseDetails, node, nodesOfDestCommunity);

            int result = updateAffinity(databaseDetails, ids);

            communityDetection(databaseDetails);
        }

        return "RefineCommunityReturns";
    }

    @Override
    public String refineCommunityUsingAffinity(DatabaseDetails databaseDetails) {
        System.out.println("In refineCommunityUsingAffinity() : " + databaseDetails.getNodesList().size());
        for (RefineNodes refineNode : databaseDetails.getNodesList()) {
            System.out.println("-----------------------------------");
            System.out.println("Source Name : " + refineNode.getSource());
            System.out.println("Dest Name : " + refineNode.getDestination());
            // Get Nodes of destination community
            List<String> nodesOfDestCommunity = getDestCommunityNodes(databaseDetails, refineNode);
            System.out.println("nodesOfDestCommunity : " + nodesOfDestCommunity);

            Nodes node = new Nodes();
            node.setName(refineNode.getSource());
            List<Integer> ids = getIdsOfMatchedEdges(databaseDetails, node, nodesOfDestCommunity);

            int result = updateAffinity(databaseDetails, ids);

        }
        communityDetection(databaseDetails);
        return null;
    }

    private int updateAffinityOfEdgesBtwSrcAndDestCommunity(DatabaseDetails databaseDetails, Nodes node, List<String> nodesOfDestCommunity) {


        return 0;
    }

    private int updateAffinity(DatabaseDetails databaseDetails, List<Integer> ids) {
        String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);
        Connection connection = null;
        try {
            connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());
            // Update Query
            String updateQuery = "UPDATE EDGES SET TOTAL_AFFINITY = 1 WHERE TABLE_SET_NAME = ? AND ID IN (%s)";

            String palceHolder = getQuestionMarkStrForPrepStmt(ids.size());
            updateQuery = String.format(updateQuery, palceHolder);

            PreparedStatement statement = connection.prepareStatement(updateQuery);
            statement.setString(1, databaseDetails.getSqlSetName());

            int offset = 1;
            for (int i = 0; i < ids.size(); i++) {
                statement.setInt(offset + i + 1, ids.get(i));
            }

            int rowsUpdated = statement.executeUpdate();
            System.out.println("No of Rows Updated :: " + rowsUpdated);
            statement.close();
            return rowsUpdated;
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            try {
                if (connection != null) {
                    connection.close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        return 0;
    }

    private List<Integer> getIdsOfMatchedEdges(DatabaseDetails databaseDetails, Nodes node, List<String> nodesOfDestCommunity) {
        databaseDetails = draUtilsImpl.setDatabaseDetails(databaseDetails);
        String dbUrlConnectionStr = draUtilsImpl.formDbConnectionStr(databaseDetails);

        String getIdsOfMatchedEdgesQuery = "SELECT DISTINCT(ID) AS MATCHED_IDS FROM EDGES\n" +
                "WHERE (TABLE2 = '"+node.getName()+"' AND TABLE1 IN (%1$s))\n" +
                "OR (TABLE1 = '"+node.getName()+"' AND TABLE2 IN (%2$s))";

        String questionMarkStrForPrepStmt = getQuestionMarkStrForPrepStmt(nodesOfDestCommunity.size());

        getIdsOfMatchedEdgesQuery = String.format(getIdsOfMatchedEdgesQuery, questionMarkStrForPrepStmt, questionMarkStrForPrepStmt);

        Connection connection = null;
        List<Integer> idsList = new ArrayList<>();
        try {
            // Establishing a connection to the database
            connection = DriverManager.getConnection(dbUrlConnectionStr, databaseDetails.getUsername(), databaseDetails.getPassword());

            PreparedStatement statement = connection.prepareStatement(getIdsOfMatchedEdgesQuery);

            for (int i = 0; i < nodesOfDestCommunity.size(); i++) {
                statement.setString(i + 1, nodesOfDestCommunity.get(i));
            }

            // Set the values for the second IN condition
            int offset = nodesOfDestCommunity.size();
            for (int i = 0; i < nodesOfDestCommunity.size(); i++) {
                statement.setString(offset + i + 1, nodesOfDestCommunity.get(i));
            }
            System.out.println("QUERY FORMED : " + getGeneratedQuery(statement));
            ResultSet resultSet = statement.executeQuery();
            while (resultSet.next()) {
                // Retrieve column values from the current row
                idsList.add(resultSet.getInt("MATCHED_IDS"));
            }
            System.out.println("idsList :: " + idsList);
        } catch (SQLException e) {
            System.out.println("SQLException, Error Code :: " + e.getErrorCode());
            e.printStackTrace();
        } finally {
            // Closing the resources
            try {
                if (connection != null) {
                    connection.close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        return idsList;
    }

    public static String getGeneratedQuery(PreparedStatement preparedStatement) {
        String query = preparedStatement.toString();
        /*int startIndex = query.indexOf(": ");
        if (startIndex != -1) {
            query = query.substring(startIndex + 2);
        }*/
        return query;
    }
    private String getQuestionMarkStrForPrepStmt(int sizeOfList) {
        StringBuilder builder = new StringBuilder();
        for(int i = 0 ; i < sizeOfList; i++) {
            builder.append("?,");
        }
        String placeHolders =  builder.deleteCharAt( builder.length() -1 ).toString();
        return placeHolders;
    }

    private List<String> getDestCommunityNodes(DatabaseDetails databaseDetails, RefineNodes refineNode) {
        String jsonString = viewCommunity(databaseDetails);
        List<String> resultStrList = new ArrayList<>();
        try {
            GraphData graphData = new ObjectMapper().readValue(jsonString, GraphData.class);
            List<Nodes> nodes = graphData.getNodes();

            // Get the color of Destination Node
            Nodes destNode =  nodes.stream().filter(nodeItem -> nodeItem.getName().equals(refineNode.getDestination())).findFirst().get();
            System.out.println("Source Node :: " + refineNode.toString());

            System.out.println("Dest Node :: " + destNode.toString());

            // Get the nodes which are same color as Destination Node
            // (If color of Destination Node is RED, get all the nodes which are in RED color
            List<Nodes> nodesOfDestCommunity = nodes.stream().filter(nodeItem -> nodeItem.getColor().equals(destNode.getColor())).collect(Collectors.toList());
            System.out.println("nodesOfDestCommunity objects :: " + nodesOfDestCommunity.toString());
            System.out.println("Input Color Selected :: " + destNode.getColor());
            for (Nodes node1 : nodesOfDestCommunity) {
                if (destNode.getColor().equals(node1.getColor())) {
                    resultStrList.add(node1.getName());
                }
            }
            System.out.println("Destination Nodes TO Update :: " + resultStrList.toString());
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }
        return resultStrList;
    }

    private List<String> getNodesOfDestCommunity(DatabaseDetails databaseDetails, Nodes inputNode) {
        String jsonString = viewCommunity(databaseDetails);
        //String srcNodeName = node.getName();
        List<String> resultStrList = new ArrayList<>();
        try {
            GraphData graphData = new ObjectMapper().readValue(jsonString, GraphData.class);
            List<Nodes> nodes = graphData.getNodes();
            List<Nodes> nodesOfDestCommunity = nodes.stream().filter(nodeItem -> nodeItem.getColor().equals(inputNode.getColor())).collect(Collectors.toList());
            System.out.println("nodesOfDestCommunity objects :: " + nodesOfDestCommunity.toString());
            System.out.println("Input Color Selected :: " + inputNode.getColor());
            for (Nodes node1 : nodesOfDestCommunity) {
                if (inputNode.getColor().equals(node1.getColor())) {
                    resultStrList.add(node1.getName());
                }
            }
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }
        return resultStrList;
    }



}
