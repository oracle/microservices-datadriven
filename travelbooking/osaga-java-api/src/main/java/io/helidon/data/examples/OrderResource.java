/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import java.io.IOException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.inject.Named;
import javax.ws.rs.*;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import oracle.ucp.jdbc.PoolDataSource;
import org.eclipse.microprofile.metrics.annotation.Counted;
import org.eclipse.microprofile.metrics.annotation.Timed;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.enums.SchemaType;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.media.Schema;
import org.eclipse.microprofile.openapi.annotations.parameters.Parameter;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponses;
import org.eclipse.microprofile.opentracing.Traced;
import io.opentracing.Tracer;
import io.opentracing.Span;

@Path("/")
@ApplicationScoped
@Traced
public class OrderResource {

    @Inject
    @Named("travelagencypdb")
    PoolDataSource atpOrderPdb;

    @Inject
    private Tracer tracer;

    OrderServiceEventProducer travelagencyServiceEventProducer = new OrderServiceEventProducer(this);
    static String regionId = System.getenv("OCI_REGION");
    static String pwSecretOcid = System.getenv("VAULT_SECRET_OCID");
    static String pwSecretFromK8s = System.getenv("dbpassword");
    static final String travelagencyQueueOwner =  System.getenv("oracle.ucp.jdbc.PoolDataSource.travelagencypdb.user"); //"ORDERUSER";
    static final String travelagencyQueueName =   System.getenv("travelagencyqueuename"); // "travelagencyqueue";
    static final String participantQueueName = System.getenv("participantqueuename"); //  "participantqueue";
    static boolean liveliness = true;
    static boolean readiness = true;
    private static String lastContainerStartTime;
    static boolean crashAfterInsert;
    static boolean crashAfterInventoryMessageReceived;
    private OrderServiceCPUStress travelagencyServiceCPUStress = new OrderServiceCPUStress();

    @Path("/lastContainerStartTime")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response lastContainerStartTime() {
        System.out.println("--->lastContainerStartTime...");
        return Response.ok()
                .entity("lastContainerStartTime = " + lastContainerStartTime)
                .build();
    }

    public void init() throws SQLException {
//    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws SQLException {
        System.out.println("OrderResource.init System.getenv(\"oracle.ucp.jdbc.PoolDataSource.travelagencypdb.user\"):" +  System.getenv("oracle.ucp.jdbc.PoolDataSource.travelagencypdb.user"));
        System.out.println("OrderResource. System.getenv(\"travelagencyqueuename\") " +  System.getenv("travelagencyqueuename"));
        System.out.println("OrderResource.System.getenv(\"participantqueuename\"); " + System.getenv("participantqueuename"));
        atpOrderPdb.setUser(travelagencyQueueOwner);
        String pw;
        if(pwSecretOcid != null && !pwSecretOcid.trim().equals("")) {
            pw = OCISDKUtility.getSecreteFromVault(true, regionId, pwSecretOcid);
        } else {
            pw = pwSecretFromK8s;
        }
        atpOrderPdb.setPassword(pw);
        Connection connection = atpOrderPdb.getConnection();
        System.out.println("OrderResource.init atpOrderPdb.getConnection():" + connection);
        connection.close();
        startEventConsumer();
        lastContainerStartTime = new java.util.Date().toString();
        System.out.println("____________________________________________________");
        System.out.println("----------->OrderResource (container) starting at: " + lastContainerStartTime);
        System.out.println("____________________________________________________");
        System.setProperty("oracle.jdbc.fanEnabled", "false");
    }

    private void startEventConsumer() {
        System.out.println("OrderResource.startEventConsumerIfNotStarted startEventConsumer...");
        OrderServiceEventConsumer travelagencyServiceEventConsumer = new OrderServiceEventConsumer(this);
        new Thread(travelagencyServiceEventConsumer).start();
    }

    Tracer getTracer() {
        return tracer;
    }

    @Operation(summary = "Places a new travelagency",
            description = "Orders a specific item for delivery to a location")
    @APIResponses({
            @APIResponse(
                    responseCode = "200",
                    description = "Confirmation of a successfully-placed travelagency",
                    content = @Content(mediaType = "text/plain")
            ),
            @APIResponse(
                    responseCode = "500",
                    description = "Error report of a failure to place an travelagency",
                    content = @Content(mediaType = "text/plain")
            )
    })
    @Path("/placeOrder")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Traced(operationName = "OrderResource.placeOrder")
    @Timed(name = "travelagency_placeOrder_timed") //length of time of an object
    @Counted(name = "travelagency_placeOrder_counted") //amount of invocations
    public Response placeOrder(
            @Parameter(description = "The travelagency ID for the travelagency",
                    required = true,
                    example = "66",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("travelagencyid") String travelagencyid,

            @Parameter(description = "The item ID of the item being travelagencyed",
                    required = true,
                    example = "sushi",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("itemid") String itemid,

            @Parameter(description = "Where the item should be delivered",
                    required = true,
                    example = "Home",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("deliverylocation") String deliverylocation) {
        System.out.println("--->placeOrder... travelagencyid:" + travelagencyid + " itemid:" + itemid);
        Span activeSpan = tracer.buildSpan("travelagencyDetail").asChildOf(tracer.activeSpan()).start();
        String traceid = activeSpan.toString().substring(0, activeSpan.toString().indexOf(":"));
        activeSpan.log("begin placing travelagency"); // logs are for a specific moment or event within the span (in contrast to tags which should apply to the span regardless of time).
        activeSpan.setTag("travelagencyid", travelagencyid); //tags are annotations of spans in travelagency to query, filter, and comprehend trace data
        activeSpan.setTag("itemid", itemid);
        activeSpan.setTag("ecid", traceid);
        activeSpan.setTag("db.user", atpOrderPdb.getUser()); // https://github.com/opentracing/specification/blob/master/semantic_conventions.md
        activeSpan.setBaggageItem("sagaid", "sagaid" + travelagencyid); //baggage is part of SpanContext and carries data across process boundaries for access throughout the trace
        activeSpan.setBaggageItem("travelagencyid", travelagencyid);
        try {
            System.out.println("--->insertOrderAndSendEvent..." +
                    travelagencyServiceEventProducer.updateDataAndSendEvent(atpOrderPdb, travelagencyid, itemid, deliverylocation, activeSpan, traceid));
        } catch (Exception e) {
            e.printStackTrace();
            return Response.serverError()
                    .entity("travelagencyid = " + travelagencyid + " failed with exception:" + e.getCause())
                    .build();
        } finally {
            activeSpan.log("end placing travelagency");
            activeSpan.finish();
        }
        return Response.ok()
                .entity("travelagencyid = " + travelagencyid + " travelagencystatus = pending travelagency placed")
                .build();
    }

    @Operation(summary = "Displays an travelagency",
            description = "Displays a previously-placed travelagency, excluding if the travelagency is cached")
    @APIResponses({
            @APIResponse(
                    responseCode = "200",
                    description = "Previously-placed travelagency",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(
                                    implementation = Order.class
                            ))
            )
    })
    @Path("/showtravelagency")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Timed(name = "travelagency_showOrder_timed") //length of time of an object
    @Counted(name = "travelagency_showOrder_counted") //amount of invocations
    public Response showtravelagency(
            @Parameter(description = "The travelagency ID for the travelagency",
                    required = true,
                    example = "1",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("travelagencyid") String travelagencyId) {
        System.out.println("--->showtravelagency (via JSON/SODA query) for travelagencyId:" + travelagencyId);
        try {
            Order travelagency = travelagencyServiceEventProducer.getOrderViaSODA(atpOrderPdb.getConnection(), travelagencyId);
            String returnJSON = JsonUtils.writeValueAsString(travelagency);
            System.out.println("OrderResource.showtravelagency returnJSON:" + returnJSON);
            return Response.ok()
                    .entity(returnJSON)
                    .build();
        } catch (Exception e) {
            e.printStackTrace();
            return Response.serverError()
                    .entity("showtravelagency travelagencyid = " + travelagencyId + " failed with exception:" + e.toString())
                    .build();
        }

    }


    @Operation(summary = "Deletes an travelagency",
            description = "Deletes a previously-placed travelagency")
    @APIResponses({
            @APIResponse(
                    responseCode = "200",
                    description = "Confirmation/result of the travelagency deletion",
                    content = @Content(mediaType = "text/plain")
            )
    })
    @Path("/deletetravelagency")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response deletetravelagency(
            @Parameter(description = "The travelagency ID for the travelagency",
                    required = true,
                    example = "1",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("travelagencyid") String travelagencyId) {
        System.out.println("--->deletetravelagency for travelagencyId:" + travelagencyId);
        String returnString = "travelagencyId = " + travelagencyId + "<br>";
        try {
            returnString += travelagencyServiceEventProducer.deleteOrderViaSODA(atpOrderPdb, travelagencyId);
            return Response.ok()
                    .entity(returnString)
                    .build();
        } catch (Exception e) {
            e.printStackTrace();
            return Response.ok()
                    .entity("travelagencyid = " + travelagencyId + " failed with exception:" + e.toString())
                    .build();
        }
    }

    @Operation(summary = "Deletes all travelagencys",
            description = "Deletes all previously-placed travelagencys")
    @APIResponses({
            @APIResponse(
                    responseCode = "200",
                    description = "Confirmation/result of the travelagency deletion",
                    content = @Content(mediaType = "application/json")
            )
    })
    @Path("/deletealltravelagencys")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response deletealltravelagencys() {
        System.out.println("--->deletealltravelagencys");
        try {
            return Response.ok()
                    .entity(travelagencyServiceEventProducer.dropOrderViaSODA(atpOrderPdb))
                    .build();
        } catch (Exception e) {
            e.printStackTrace();
            return Response.ok()
                    .entity("deletealltravelagencys failed with exception:" + e.toString())
                    .build();
        }
    }


    @Path("/travelagencysetlivenesstofalse")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response travelagencysetlivenesstofalse() {
        liveliness = false;
        return Response.ok()
                .entity("travelagency liveness set to false - OKE should restart the pod due to liveness probe")
                .build();
    }

    @Path("/travelagencysetreadinesstofalse")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response travelagencysetreadinesstofalse() {
        liveliness = false;
        return Response.ok()
                .entity("travelagency readiness set to false")
                .build();
    }

    @Path("/startCPUStress")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response startCPUStress() {
        System.out.println("--->startCPUStress...");
        travelagencyServiceCPUStress.start();
        return Response.ok()
                .entity("CPU stress started")
                .build();
    }

    @Path("/stopCPUStress")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response stopCPUStress() {
        System.out.println("--->stopCPUStress...");
        travelagencyServiceCPUStress.stop();
        return Response.ok()
                .entity("CPU stress stopped")
                .build();
    }


    @Path("/crashAfterInsert")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response crashAfterInsert() {
        crashAfterInsert = true;
        return Response.ok()
                .entity("travelagency crashAfterInsert set")
                .build();
    }

    @Path("/crashAfterInventoryMessageReceived")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response crashAfterInventoryMessageReceived() {
        crashAfterInventoryMessageReceived = true;
        return Response.ok()
                .entity("travelagency crashAfterInventoryMessageReceived set")
                .build();
    }






    @Path("/placeOrderWithoutOSaga")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response placeOrderWithoutOSaga(@QueryParam("isCommit") boolean isCommit) throws SQLException {
        System.out.println("--->placeOrderWithoutOSaga... isCommit:" + isCommit);
        return Response.ok()
                .entity(new OSagaComparison().withoutOSaga(atpOrderPdb.getConnection(), "66", isCommit))
                .build();
    }

    @Path("/placeOrderWithOSaga")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response placeOrderWithOSaga( @QueryParam("isCommit") boolean isCommit) throws SQLException {
        System.out.println("--->placeOrderWithOSaga...  isCommit:" + isCommit);
        return Response.ok()
                .entity(new OSagaComparison().withOSaga(atpOrderPdb.getConnection(), "66", isCommit))
                .build();
    }

    @Path("/beginSaga")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response beginSaga( ) throws SQLException {
        System.out.println("--->beginSaga");
        return Response.ok()
                .entity("sagaId:" + new ImplementionWithOSaga().beginOSaga(atpOrderPdb.getConnection(), "66"))
                .build();
    }


    @Path("/getOSagaInfo")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response getOSagaInfo() throws SQLException {
        System.out.println("--->getOSagaInfo...");
        ResultSet resultSet = atpOrderPdb.getConnection().createStatement().executeQuery(
                " select id, initiator, coordinator, owner, begin_time, status from sys.saga$");
        String id, status;
        String returnString = "getOSagaInfo...";
        while (resultSet.next()) {
            id = resultSet.getString("id");
            status = resultSet.getString("status");
            returnString += " id:" + id + " status:" + status + "\n";
        }
        return Response.ok()
                .entity(returnString)
                .build();
    }


    @Path("/joinSaga")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response joinSaga(@QueryParam("PARTICIPANTTYPE") String PARTICIPANTTYPE,
                             @QueryParam("RESERVATIONTYPE") String RESERVATIONTYPE,
                             @QueryParam("RESERVATIONVALUE") String RESERVATIONVALUE,
                             @QueryParam("SAGANAME") String SAGANAME,
                             @QueryParam("SAGAID") String SAGAID) throws SQLException {
        System.out.println("--->joinSaga calling dbms_saga.enroll_participant for   PARTICIPANTTYPE = " + PARTICIPANTTYPE + ", RESERVATIONTYPE = " + RESERVATIONTYPE +
                ", RESERVATIONVALUE = " + RESERVATIONVALUE + ", SAGANAME = " + SAGANAME + ", SAGAID = " + SAGAID);
        CallableStatement cstmt = atpOrderPdb.getConnection().prepareCall("{call REGISTER_PARTICIPANT_IN_SAGA(?,?,?,?,?)}");
//        cstmt.setString("PARTICIPANTTYPE", "Airline");
        cstmt.setString("PARTICIPANTTYPE", "JavaAirline");
        cstmt.setString("RESERVATIONTYPE", "flight");
        cstmt.setString("RESERVATIONVALUE", "United");
        cstmt.setString("SAGANAME", "TravelAgency");
        cstmt.setBytes("SAGAID", oracle.sql.RAW.hexString2Bytes(SAGAID));
        cstmt.execute();
        return Response.ok()
                .entity("joinSaga success for sagaid:" + SAGAID)
                .build();
    }

    @Path("/commitSaga")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response commitSaga(@QueryParam("sagaid") String sagaid) throws SQLException {
        System.out.println("--->commitSaga calling dbms_saga.commit_saga...");
        makeRequest("http://localhost:8030/commitSaga?sagaid=" + sagaid);
        return Response.ok()
                .entity("commitSaga" + callCommitOnSaga(atpOrderPdb.getConnection(), sagaid))
                .build();
    }


    String callCommitOnSaga(Connection connection, String sagaId)  throws SQLException {
        CallableStatement cstmt  = connection.prepareCall("{call COMMITSAGA(?)}");
        cstmt.setString(1, sagaId);
        cstmt.execute();
        return "commitSaga (ImplementionWithOSaga) sagaId:" + sagaId;
    }


    @Path("/rollbackSaga")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response rollbackSaga(@QueryParam("sagaid") String sagaid) throws SQLException {
        System.out.println("--->rollbackSaga calling dbms_saga.rollback_saga...");
        //this rest call represents the message call that would be made from the db layer when
        //  callRollbackOnSaga/ROLLBACKSAGA/dbms_saga.rollback_saga
        makeRequest("http://localhost:8030/rollbackSaga?sagaid=" + sagaid);
        return Response.ok()
                .entity("rollbackSaga" + callRollbackOnSaga(atpOrderPdb.getConnection(), sagaid))
                .build();
    }

    String callRollbackOnSaga(Connection connection,String sagaId)  throws SQLException {
        CallableStatement cstmt  = connection.prepareCall("{call ROLLBACKSAGA(?)}");
        cstmt.setString(1, sagaId);
        cstmt.execute();
        return "rollbackSaga (ImplementionWithOSaga) sagaId:" + sagaId;
    }

    @Path("/bookTravel")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response bookTravel() throws SQLException, IOException {
        System.out.println("--->bookTravel...");
        String sagaid = new ImplementionWithOSaga().beginOSaga(atpOrderPdb.getConnection(), "66");
        System.out.println("--->bookTravel dbms_saga.begin_saga returned sagaid:" + sagaid);
        System.out.println("--->bookTravel calling flight service...");
        return Response.ok()
                .entity(makeRequest("http://localhost:8030/reserveFlight?sagaid=" + sagaid))
                .build();
    }

    private String makeRequest(String url)  {
        Client client = ClientBuilder.newBuilder()
                .build();
        Response response = client.target(url).request().get();
        String entity = response.readEntity(String.class);
        return entity;
    }
}