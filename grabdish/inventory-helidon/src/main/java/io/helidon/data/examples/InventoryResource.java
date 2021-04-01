/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import java.sql.Connection;
import java.sql.SQLException;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.context.Initialized;
import javax.enterprise.event.Observes;
import javax.inject.Inject;
import javax.inject.Named;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import oracle.ucp.jdbc.PoolDataSource;

@Path("/")
@ApplicationScoped
public class InventoryResource {

    @Inject
    @Named("inventorypdb")
    PoolDataSource atpInventoryPDB;
    static String regionId = System.getenv("OCI_REGION").trim();
    static String pwSecretOcid = System.getenv("VAULT_SECRET_OCID").trim();
    static String pwSecretFromK8s = System.getenv("dbpassword").trim();
    static String inventoryuser = "INVENTORYUSER";
    static String inventorypw;
    static String inventoryQueueName = "inventoryqueue";
    static String orderQueueName = "orderqueue";

    static {
        System.setProperty("oracle.jdbc.fanEnabled", "false");
    }

    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws SQLException {
        System.out.println("InventoryResource.init " + init);
        String pw;
        if(!pwSecretOcid.trim().equals("")) {
            pw = OCISDKUtility.getSecreteFromVault(true, regionId, pwSecretOcid);
        } else {
            pw = pwSecretFromK8s;
        }
        inventorypw = pw;
        atpInventoryPDB.setUser(inventoryuser);
        atpInventoryPDB.setPassword(pw);
        inventoryuser = atpInventoryPDB.getUser();
        System.out.println("InventoryResource.init inventoryuser:" + inventoryuser + " inventorypw:" + inventorypw);
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

}
