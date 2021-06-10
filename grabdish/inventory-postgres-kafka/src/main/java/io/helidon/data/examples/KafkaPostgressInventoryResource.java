/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.context.Initialized;
import javax.enterprise.event.Observes;
import javax.inject.Inject;
import javax.inject.Named;
import javax.sql.DataSource;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

@Path("/")
@ApplicationScoped
public class KafkaPostgressInventoryResource {


    @Inject
    @Named("postgresDataSource")
    DataSource postgresDataSource;

    static boolean crashAfterOrderMessageReceived;
    static boolean crashAfterOrderMessageProcessed;

    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws SQLException {
        System.out.println("InventoryResource.init KafkaPostgresOrderEventConsumer().testConnection() " + init);
        listenForMessages();
    }

    public Response listenForMessages() throws SQLException {
        new Thread(new KafkaPostgresOrderEventConsumer(this)).start();
        final Response returnValue = Response.ok()
                .entity("now listening for messages...")
                .build();
        return returnValue;
    }

    @Path("/addInventory")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response addInventory(@QueryParam("itemid") String itemid) {
        String response;
        System.out.println("KafkaPostgressInventoryResource.addInventory itemid:" + itemid);
        try {
            Connection conn = postgresDataSource.getConnection();
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
    public Response removeInventory(@QueryParam("itemid") String itemid) {
        String response;
        System.out.println("KafkaPostgressInventoryResource.removeInventory itemid:" + itemid);
        try (Connection conn = postgresDataSource.getConnection()) {
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

    @Path("/getInventory")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response getInventoryCount(@QueryParam("itemid") String itemid) {
        String response;
        System.out.println("KafkaPostgressInventoryResource.getInventoryCount itemid:" + itemid);
        try (Connection conn = postgresDataSource.getConnection()) {
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
            System.out.println("KafkaPostgressInventoryResource.getInventoryCount inventorycount:" + inventorycount);
        } else inventorycount = 0;
        conn.close();
        return "inventorycount for " + itemid + " is now " + inventorycount;
    }

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
}
