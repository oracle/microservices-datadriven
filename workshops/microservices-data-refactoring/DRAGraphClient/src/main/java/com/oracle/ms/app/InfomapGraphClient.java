package com.oracle.ms.app;


import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.google.common.base.Supplier;

import oracle.pg.rdbms.AdbGraphClient;
import oracle.pg.rdbms.AdbGraphClientConfiguration;
import oracle.pgx.api.PgxGraph;
import oracle.pgx.api.Analyst;
import oracle.pgx.api.EdgeProperty;
import oracle.pgx.api.Partition;
import oracle.pgx.api.PgxSession;
import oracle.pgx.api.PgxVertex;
import oracle.pgx.api.ServerInstance;
import oracle.pgx.api.VertexCollection;
import oracle.pgx.api.VertexProperty;
import oracle.pgx.common.types.PropertyType;
import oracle.pgx.config.GraphConfig;
import oracle.pgx.config.GraphConfigBuilder;

public class InfomapGraphClient {

	public static void main(String[] args) throws ExecutionException, InterruptedException {
		
		FileProperties properties = new FileProperties();
		var config = AdbGraphClientConfiguration.builder();
		config.tenant(properties.readProperty(Constants.TENANT_STR));
		config.database(properties.readProperty(Constants.DATABASE_STR));
		config.username(properties.readProperty(Constants.DB_USERNAME_STR));
		config.password(properties.readProperty(Constants.DB_PASSWORD_STR));
		config.endpoint(properties.readProperty(Constants.DB_ENDPOINT_STR));
		
		var client = new AdbGraphClient(config.build());
		
		if (!client.isAttached()) {
			var job = client.startEnvironment(10);
			job.get();
			System.out.println("job details: name=" + job.getName() + "type= " + job.getType() + "created_by= " + job.getCreatedBy());
		}

		ServerInstance instance = client.getPgxInstance();
		PgxSession session = instance.createSession(Constants.SESSION_NAME_STR);
		//MED_REC_PG_OBJ_G
		//MED_RECS_NEW_G - 259 nodes
		//PgxGraph graph = session.readGraphByName("MED_RECS_NEW_G", oracle.pgx.api.GraphSource.PG_VIEW);
		
		
		GraphConfig graphConfig = 
				GraphConfigBuilder.forPropertyGraphRdbms()
				.setName(properties.readGraphProperty(Constants.GRAPH_NAME_STR))
				.addVertexProperty(properties.readGraphProperty(Constants.VERTEX_COLUMN_STR), PropertyType.STRING)
				.addEdgeProperty(properties.readGraphProperty(Constants.EDGE_SOURCE_COL_STR), PropertyType.STRING)
				.addEdgeProperty(properties.readGraphProperty(Constants.EDGE_DESTINATION_COL_STR), PropertyType.STRING)
				.addEdgeProperty(properties.readGraphProperty(Constants.EDGE_WEIGHT_COL_STR), PropertyType.DOUBLE)
				.setLoadVertexLabels(true)
				.setLoadEdgeLabel(true)
				.build();
		PgxGraph graph = session.readGraphWithProperties(graphConfig);
		
		System.out.println("Graph : " + graph);
		Analyst analyst = session.createAnalyst();
		
		// Default Max Iteration for Infomap is set to 1.
		int maxIterations = 1;
		String targetCommunityTableName = null;
		try {
			if (args.length > 0) {
				maxIterations = Integer.parseInt(args[0]);
			}
			if (args.length > 1) {
				targetCommunityTableName = args[1];
			}
		} catch (ArrayIndexOutOfBoundsException aiex) {
			aiex.printStackTrace();
		} catch (Exception ex) {
			ex.printStackTrace();
		}
		
		EdgeProperty<Double> weight = graph.getEdgeProperty(properties.readGraphProperty(Constants.EDGE_WEIGHT_COL_STR));
		try {
			VertexProperty<Integer, Double> rank = analyst.weightedPagerank(graph, 1e-16, 0.85, 1000, true, weight);
			VertexProperty<Integer, Long> module = graph.createVertexProperty(PropertyType.LONG, Constants.COMMUNITY_STR);
			System.out.println("Calling Infomap with Max Iterations = " + maxIterations);
			Partition<Integer> promise = analyst.communitiesInfomap(graph, rank, weight, 0.15, 0.0001, maxIterations, module);
			graph.queryPgql("SELECT n." + Constants.COMMUNITY_STR + ",n.TABLE_NAME FROM MATCH (n) order by n." + Constants.COMMUNITY_STR + "").print().close();
			if (targetCommunityTableName != null) {
				System.out.println("Below are the Nodes of Selected Community : " + targetCommunityTableName);
				graph.queryPgql("SELECT n." + Constants.COMMUNITY_STR + " FROM MATCH (n) where n.TABLE_NAME = '" + targetCommunityTableName + "'").print().close();
				System.out.println("SELECT n.TABLE_NAME FROM MATCH (n) WHERE n." + Constants.COMMUNITY_STR + " IN (SELECT n." + Constants.COMMUNITY_STR + " FROM MATCH (n) where n.TABLE_NAME = '" + targetCommunityTableName + "')");
				graph.queryPgql("SELECT n.TABLE_NAME FROM MATCH (n) WHERE n." + Constants.COMMUNITY_STR + " IN (SELECT n." + Constants.COMMUNITY_STR + " FROM MATCH (n) where n.TABLE_NAME = '" + targetCommunityTableName + "')").print().close();
			}
			
			/*
			for (VertexCollection<Integer> partition : promise) {
			    System.out.println("======== ===== =====partition : " + partition);
			    for (PgxVertex<Integer> vertexInCommunity : partition){
			    	System.out.println("Res : " + vertexInCommunity.getProperty("TABLE_NAME"));
			    }
			}
			*/
		} catch (ExecutionException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		
		session.close();
		
	}
}
