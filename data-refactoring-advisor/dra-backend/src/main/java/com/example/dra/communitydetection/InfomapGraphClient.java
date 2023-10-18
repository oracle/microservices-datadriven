// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.communitydetection;

import com.example.dra.ViewGraphResponse;
import com.example.dra.entity.Nodes;
import oracle.pg.rdbms.AdbGraphClient;
import oracle.pg.rdbms.AdbGraphClientConfiguration;
import oracle.pgql.lang.PgqlException;
import oracle.pgx.api.*;
import oracle.pgx.common.types.PropertyType;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

public class InfomapGraphClient {

	public void createGraph1(PgxSession session) {
	}

	public ViewGraphResponse createGraph(String stsName) throws ExecutionException, InterruptedException {
		System.out.println("In createGraph Method");

		AdbGraphClientConfiguration.AdbGraphClientConfigurationBuilder config = AdbGraphClientConfiguration.builder();
		config.tenant("ocid1.tenancy.oc1..xxx");
		config.database("medicalrecordsdb");
		config.cloudDatabaseName("ocid1.autonomousdatabase.oc1.iad.xxx");
		config.username("ADMIN");
		config.password("xxx");
		config.endpoint("https://xxx-medicalrecordsdb.adb.us-ashburn-1.oraclecloudapps.com/");

		var client = new AdbGraphClient(config.build());
		System.out.println("Client Created using config");
		if (!client.isAttached()) {
			var job = client.startEnvironment(10);
			job.get();
			System.out.println("Job Details: Job Name=" + job.getName() + ", Job Created By= " + job.getCreatedBy());
		}

		ServerInstance instance = client.getPgxInstance();
		System.out.println("Creating Session");
		PgxSession session = instance.createSession(Constants.SESSION_NAME_STR);
		System.out.println("Session Created");

		String nodesTableViewName = "NODES_VIEW_"+stsName;
		String edgesTableViewName = "EDGES_VIEW_"+stsName;

		String statement = "CREATE PROPERTY GRAPH DRA_DEMO_GRAPH\n" +
				"  VERTEX TABLES (\n" +
				"    ADMIN."+nodesTableViewName+"\n" +
				"      KEY ( table_name )\n" +
				"      PROPERTIES ( schema, tables_joined, id, table_name, table_set_name, total_executions, total_sql )\n" +
				"  )\n" +
				"  EDGE TABLES (ADMIN."+edgesTableViewName+" SOURCE KEY ( table1 ) REFERENCES "+nodesTableViewName+"\n" +
				"      DESTINATION KEY ( table2 ) REFERENCES "+nodesTableViewName+"\n" +
				"      PROPERTIES ( dynamic_coefficient, join_count, join_executions, static_coefficient, table1, table2, id, table_set_name, total_affinity)\n" +
				"  )";

		session.executePgql(statement);

		ViewGraphResponse viewGraphResponse = new ViewGraphResponse();
		List<Nodes> nodes = new ArrayList<>();
		Map<Integer,String> colorMap = new HashMap<Integer,String>();
		colorMap.put(0,"Red");
		colorMap.put(1,"Green");
		colorMap.put(2,"Yellow");
		colorMap.put(3,"Orange");
		colorMap.put(4,"Grey");
		colorMap.put(5, "Pink");
		colorMap.put(6, "Maroon");
		colorMap.put(7,"Purple");


		PgxGraph graph = session.getGraph("DRA_DEMO_GRAPH");
		/*System.out.println("Graph :: "  + g);*/

		//PgxGraph graph = session.readGraphByName("DRA_DEMO_GRAPH", oracle.pgx.api.GraphSource.PG_VIEW);
		// PgxGraph graph = session.readGraphWithProperties(graphConfig);

		System.out.println("Graph : " + graph);

	/*	PgxGraph subgraph = session.readSubgraph()
				.fromPgView("NEW_GRAPH")
				.queryPgql("select * from match (v)-[t]->() on DRA_DEMO_GRAPH Where v.table_set_name = '"+stsName+"'")
                       .load("DRA_DEMO_GRAPH");

		System.out.println("SUB-Graph : " + subgraph);
	*/
		Analyst analyst = session.createAnalyst();

		// Default Max Iteration for Infomap is set to 1.
		int maxIterations = 1;
		String targetCommunityTableName = null;

		//EdgeProperty<Double> weight = graph.getEdgeProperty(properties.readGraphProperty(Constants.EDGE_WEIGHT_COL_STR));
		EdgeProperty<Double> weight = graph.getEdgeProperty("TOTAL_AFFINITY");

		try {
			VertexProperty<Integer, Double> rank = analyst.weightedPagerank(graph, 1e-16, 0.85, 1000, true, weight);
			VertexProperty<Integer, Long> module = graph.createVertexProperty(PropertyType.LONG, Constants.COMMUNITY_STR);
			System.out.println("Calling Infomap with Max Iterations = " + maxIterations);
			Partition<Integer> promise = analyst.communitiesInfomap(graph, rank, weight, 0.15, 0.0001, maxIterations, module);
			PgqlResultSet resultSet = graph.queryPgql("SELECT n." + Constants.COMMUNITY_STR + ",n.TABLE_NAME FROM MATCH (n) order by n." + Constants.COMMUNITY_STR + "").print();
			System.out.println("PRINTING RESULT SET.....");
			System.out.println("########################################");
			Nodes node;
			for (PgxResult result : resultSet) {
				int community = result.getInteger(1);
				String tableName = result.getString(2);
				System.out.println(community + ": " + tableName);

				node = new Nodes();
				node.setName(tableName);
				node.setColor(colorMap.get(community));
				node.setCommunityNumber(community);
				nodes.add(node);
			}
			resultSet.close();

			/*int i =1;
			Nodes node;
			for (VertexCollection<Integer> partition : promise) {
				System.out.println("======== ===== =====partition : " + partition);
				for (PgxVertex<Integer> vertexInCommunity : partition){
					System.out.println("Res : " + vertexInCommunity.getProperty("TABLE_NAME"));
					String tableName = vertexInCommunity.getProperty("TABLE_NAME");
					node = new Nodes();
					node.setName(tableName);
					node.setColor(colorMap.get(i));
					nodes.add(node);
				}
				i++;
			}*/
			viewGraphResponse.setNodes(nodes);
		} catch (ExecutionException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		} catch (PgqlException e) {
			throw new RuntimeException(e);
		}

		session.close();
		return viewGraphResponse;
	}
}
