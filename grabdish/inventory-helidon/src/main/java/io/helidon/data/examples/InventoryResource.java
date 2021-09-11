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

import io.opentracing.Tracer;
import oracle.ucp.jdbc.PoolDataSource;
import org.eclipse.microprofile.metrics.Counter;
import org.eclipse.microprofile.metrics.Metadata;
import org.eclipse.microprofile.metrics.MetricRegistry;
import org.eclipse.microprofile.metrics.MetricType;

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
    static final String orderQueueName =   System.getenv("orderqueuename");
    static final String inventoryQueueName =  System.getenv("inventoryqueuename");
    static boolean crashAfterOrderMessageReceived;
    static boolean crashAfterOrderMessageProcessed;

    static {
        System.setProperty("oracle.jdbc.fanEnabled", "false");
    }

    @Inject
    private Tracer tracer;

    @Inject
    private MetricRegistry metricRegistry;

    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws SQLException {
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
        listenForMessages();
    }

    Tracer getTracer() {
        return tracer;
    }

    MetricRegistry getMetricRegistry() {
        return metricRegistry;
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
