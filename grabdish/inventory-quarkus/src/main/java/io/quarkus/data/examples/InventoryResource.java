/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.quarkus.data.examples;

import io.quarkus.runtime.StartupEvent;
import oracle.ucp.jdbc.PoolDataSource;

import io.agroal.api.AgroalDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.context.Initialized;
import javax.enterprise.event.Observes;
import javax.inject.Inject;
import javax.inject.Named;
import javax.sql.DataSource;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.sql.Connection;
import java.sql.SQLException;

@Path("/")
@ApplicationScoped
public class InventoryResource {

//    @Inject
//    @Named("inventorypdb")
//    AgroalDataSource atpInventoryPDB;
    PoolDataSource  atpInventoryPDB;
    static String inventoryuser = "INVENTORYUSER";
    static String inventorypw;
    static final String orderQueueName =   System.getenv("orderqueuename");
    static final String inventoryQueueName =  System.getenv("inventoryqueuename");
    static final String queueOwner =   System.getenv("queueowner");
    static final String inventoryUser =  System.getenv("oracle.ucp.jdbc.PoolDataSource.inventorypdb.user");
    static final String inventoryPW =  System.getenv("dbpassword");
    static final String inventoryURL =  System.getenv("oracle.ucp.jdbc.PoolDataSource.inventorypdb.URL");
    static boolean crashAfterOrderMessageReceived;
    static boolean crashAfterOrderMessageProcessed;

    static {
        System.setProperty("oracle.jdbc.fanEnabled", "false");
    }

    public void init(@Observes StartupEvent ev) throws SQLException {
        System.out.println("InventoryResource.init " + ev);
        System.out.println("InventoryResource.init oracle.ucp.jdbc.PoolDataSource.inventorypdb.URL env" + System.getenv("oracle.ucp.jdbc.PoolDataSource.inventorypdb.URL"));
        System.out.println("InventoryResource.init oracle.ucp.jdbc.PoolDataSource.inventorypdb.URL prop" + System.getProperty("oracle.ucp.jdbc.PoolDataSource.inventorypdb.URL"));
        atpInventoryPDB = PoolDataSourceFactory.getPoolDataSource();
        atpInventoryPDB.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        atpInventoryPDB.setURL(inventoryURL);
        atpInventoryPDB.setUser(inventoryUser);
        atpInventoryPDB.setPassword(inventoryPW);
        System.out.println("InventoryResource.init atpInventoryPDB:" + atpInventoryPDB);
        try (Connection connection  = atpInventoryPDB.getConnection()) { //fail if connection is not successful rather than go into listening loop
            System.out.println("InventoryResource.init connection:" + connection);
        }
        listenForMessages();
    }


    @Path("/listenForMessages")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response listenForMessages()  {
        new Thread(new InventoryServiceOrderEventConsumer(this)).start();
        final Response returnValue = Response.ok()
                .entity("now listening for messages...")
                .build();
        return returnValue;
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
