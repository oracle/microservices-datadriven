/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.context.Initialized;
import javax.enterprise.event.Observes;
import javax.inject.Inject;
import javax.inject.Named;
import javax.ws.rs.*;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import io.opentracing.Tracer;
import oracle.ucp.jdbc.PoolDataSource;
import org.eclipse.microprofile.metrics.Counter;
import org.eclipse.microprofile.metrics.Metadata;
import org.eclipse.microprofile.metrics.MetricRegistry;
import org.eclipse.microprofile.metrics.MetricType;
import org.eclipse.microprofile.opentracing.Traced;

import static io.helidon.data.examples.InventoryServiceOrderEventConsumer.INVENTORYDOESNOTEXIST;

@Path("/")
@ApplicationScoped
public class InventoryResource {

    @Inject
    @Named("inventorypdb")
    PoolDataSource atpInventoryPDB;
    static String regionId = System.getenv("OCI_REGION");
    static String pwSecretOcid = System.getenv("VAULT_SECRET_OCID");
    static String pwSecretFromK8s = System.getenv("dbpassword");
    static String inventoryuser = "INVENTORYUSER";
    static String inventorypw;
    static final String queueOwner =   System.getenv("queueowner");
    static final String orderQueueName =   System.getenv("orderqueuename");
    static final String inventoryQueueName =  System.getenv("inventoryqueuename");
    static boolean crashAfterOrderMessageReceived;
    static boolean crashAfterOrderMessageProcessed;
    private Client client;
    
    static String isSuggestiveSaleAIEnabled = System.getenv("isSuggestiveSaleAIEnabled");

    static {
        System.setProperty("oracle.jdbc.fanEnabled", "false");
    }
    
    public InventoryResource() {
        client = ClientBuilder.newBuilder().build();
    }

    @Inject
    private Tracer tracer;

    @Inject
    private MetricRegistry metricRegistry;

    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws Exception {
        System.out.println("InventoryResource.init " + init);
        String pw;
        if(pwSecretOcid != null && !pwSecretOcid.equals("")) {
            pw = OCISDKUtility.getSecreteFromVault(true, regionId, pwSecretOcid);
        } else {
            pw = pwSecretFromK8s;
        }
        inventorypw = pw;
        atpInventoryPDB.setUser(inventoryuser);
        atpInventoryPDB.setPassword(pw);
        inventoryuser = atpInventoryPDB.getUser();
        try (Connection connection  = atpInventoryPDB.getConnection()) { //fail if connection is not successful rather than go into listening loop
            System.out.println("InventoryResource.init connection:" + connection);
        }
        new Thread(new InventoryServiceOrderEventConsumer(this)).start();
    }

    Tracer getTracer() {
        return tracer;
    }

    MetricRegistry getMetricRegistry() {
        return metricRegistry;
    }


    // begin supplier service

    @Path("/addInventory")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response  addInventory(@QueryParam("itemid") String itemid) {
        String response;
        System.out.println("SupplierService.addInventory itemid:" + itemid);
        try {
            Connection conn = atpInventoryPDB.getConnection();
            conn.createStatement().execute(
                    "UPDATE inventory SET inventorycount = inventorycount + 1 where inventoryid = '" + itemid + "'");
            response = getInventoryCount(itemid, conn);
        } catch (SQLException ex) {
            response = ex.getMessage();
        }
        return Response.ok()
                .entity(response)
                .build();
    }

    @Path("/removeInventory")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response  removeInventory(@QueryParam("itemid") String itemid) {
        String response;
        System.out.println("SupplierService.removeInventory itemid:" + itemid);
        try (Connection conn = atpInventoryPDB.getConnection()) {
            conn.createStatement().execute(
                    "UPDATE inventory SET inventorycount = inventorycount - 1 where inventoryid = '" + itemid + "'");
            response = getInventoryCount(itemid, conn);
        } catch (SQLException ex) {
            response = ex.getMessage();
        }
        return Response.ok()
                .entity(response)
                .build();
    }

    @Path("/getInventoryCount")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response  getInventoryCount(@QueryParam("itemid") String itemid) {
        String response;
        System.out.println("SupplierService.getInventoryCount itemid:" + itemid);
        try (Connection conn = atpInventoryPDB.getConnection()) {
            response = getInventoryCount(itemid, conn);
        } catch (SQLException ex) {
            response = ex.getMessage();
        }
        return Response.ok()
                .entity(response)
                .build();
    }

    private String getInventoryCount(String itemid, Connection conn) throws SQLException {
        ResultSet resultSet = conn.createStatement().executeQuery(
                "select inventorycount from inventory  where inventoryid = '" + itemid + "'");
        int inventorycount;
        if (resultSet.next()) {
            inventorycount = resultSet.getInt("inventorycount");
            System.out.println("SupplierService.getInventoryCount inventorycount:" + inventorycount);
        } else inventorycount = 0;
        conn.close();
        return "inventorycount for " + itemid + " is now " + inventorycount;
    }

    //end supplier service



    @Path("/crashAfterOrderMessageReceived")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response crashAfterOrderMessageReceived() {
        crashAfterOrderMessageReceived = true;
        return Response.ok()
                .entity("inventory crashAfterOrderMessageReceived set")
                .build();
    }

    @Path("/crashAfterOrderMessageProcessed")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response crashAfterOrderMessageProcessed() {
        crashAfterOrderMessageProcessed = true;
        return Response.ok()
                .entity("inventory crashAfterOrderMessageProcessed set")
                .build();
    }
    
    public String foodWinePairingService(String itemid) throws IOException {
    	try {
    		String url = "http://foodwinepairing.msdataworkshop:8080/foodwinepairing/"+itemid;
    		System.out.println("Food Wine Pairing Request url : " + url);
    		Response response = client.target(url).request().get();
    		System.out.println("Food Wine Pairing Response.toString : " + response.toString());
    		String entity = response.readEntity(String.class);
    		System.out.println("Recommended Wines from FoodWinePairing Python Service : " + entity);
    		return entity;
    	} catch (Exception e) {
    		e.printStackTrace();
    	}
    	return "No Wines Suggested";
    }

}
