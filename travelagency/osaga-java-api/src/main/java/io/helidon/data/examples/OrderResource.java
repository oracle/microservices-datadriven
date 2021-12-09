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
    @Named("orderpdb")
    PoolDataSource atpOrderPdb;

    @Inject
    private Tracer tracer;

    OrderServiceEventProducer orderServiceEventProducer = new OrderServiceEventProducer(this);
    static String regionId = System.getenv("OCI_REGION");
    static String pwSecretOcid = System.getenv("VAULT_SECRET_OCID");
    static String pwSecretFromK8s = System.getenv("dbpassword");
    static final String orderQueueOwner =  System.getenv("oracle.ucp.jdbc.PoolDataSource.orderpdb.user"); //"ORDERUSER";
    static final String orderQueueName =   System.getenv("orderqueuename"); // "orderqueue";
    static final String inventoryQueueName = System.getenv("inventoryqueuename"); //  "inventoryqueue";
    static boolean liveliness = true;
    static boolean readiness = true;
    private static String lastContainerStartTime;
    static boolean crashAfterInsert;
    static boolean crashAfterInventoryMessageReceived;
    private OrderServiceCPUStress orderServiceCPUStress = new OrderServiceCPUStress();

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
        System.out.println("OrderResource.init System.getenv(\"oracle.ucp.jdbc.PoolDataSource.orderpdb.user\"):" +  System.getenv("oracle.ucp.jdbc.PoolDataSource.orderpdb.user"));
        System.out.println("OrderResource. System.getenv(\"orderqueuename\") " +  System.getenv("orderqueuename"));
        System.out.println("OrderResource.System.getenv(\"inventoryqueuename\"); " + System.getenv("inventoryqueuename"));
        atpOrderPdb.setUser(orderQueueOwner);
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
        OrderServiceEventConsumer orderServiceEventConsumer = new OrderServiceEventConsumer(this);
        new Thread(orderServiceEventConsumer).start();
    }

    Tracer getTracer() {
        return tracer;
    }

    @Operation(summary = "Places a new order",
            description = "Orders a specific item for delivery to a location")
    @APIResponses({
            @APIResponse(
                    responseCode = "200",
                    description = "Confirmation of a successfully-placed order",
                    content = @Content(mediaType = "text/plain")
            ),
            @APIResponse(
                    responseCode = "500",
                    description = "Error report of a failure to place an order",
                    content = @Content(mediaType = "text/plain")
            )
    })
    @Path("/placeOrder")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Traced(operationName = "OrderResource.placeOrder")
    @Timed(name = "order_placeOrder_timed") //length of time of an object
    @Counted(name = "order_placeOrder_counted") //amount of invocations
    public Response placeOrder(
            @Parameter(description = "The order ID for the order",
                    required = true,
                    example = "66",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("orderid") String orderid,

            @Parameter(description = "The item ID of the item being ordered",
                    required = true,
                    example = "sushi",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("itemid") String itemid,

            @Parameter(description = "Where the item should be delivered",
                    required = true,
                    example = "Home",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("deliverylocation") String deliverylocation) {
        System.out.println("--->placeOrder... orderid:" + orderid + " itemid:" + itemid);
        Span activeSpan = tracer.buildSpan("orderDetail").asChildOf(tracer.activeSpan()).start();
        String traceid = activeSpan.toString().substring(0, activeSpan.toString().indexOf(":"));
        activeSpan.log("begin placing order"); // logs are for a specific moment or event within the span (in contrast to tags which should apply to the span regardless of time).
        activeSpan.setTag("orderid", orderid); //tags are annotations of spans in order to query, filter, and comprehend trace data
        activeSpan.setTag("itemid", itemid);
        activeSpan.setTag("ecid", traceid);
        activeSpan.setTag("db.user", atpOrderPdb.getUser()); // https://github.com/opentracing/specification/blob/master/semantic_conventions.md
        activeSpan.setBaggageItem("sagaid", "sagaid" + orderid); //baggage is part of SpanContext and carries data across process boundaries for access throughout the trace
        activeSpan.setBaggageItem("orderid", orderid);
        try {
            System.out.println("--->insertOrderAndSendEvent..." +
                    orderServiceEventProducer.updateDataAndSendEvent(atpOrderPdb, orderid, itemid, deliverylocation, activeSpan, traceid));
        } catch (Exception e) {
            e.printStackTrace();
            return Response.serverError()
                    .entity("orderid = " + orderid + " failed with exception:" + e.getCause())
                    .build();
        } finally {
            activeSpan.log("end placing order");
            activeSpan.finish();
        }
        return Response.ok()
                .entity("orderid = " + orderid + " orderstatus = pending order placed")
                .build();
    }

    @Operation(summary = "Displays an order",
            description = "Displays a previously-placed order, excluding if the order is cached")
    @APIResponses({
            @APIResponse(
                    responseCode = "200",
                    description = "Previously-placed order",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(
                                    implementation = Order.class
                            ))
            )
    })
    @Path("/showorder")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Timed(name = "order_showOrder_timed") //length of time of an object
    @Counted(name = "order_showOrder_counted") //amount of invocations
    public Response showorder(
            @Parameter(description = "The order ID for the order",
                    required = true,
                    example = "1",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("orderid") String orderId) {
        System.out.println("--->showorder (via JSON/SODA query) for orderId:" + orderId);
        try {
            Order order = orderServiceEventProducer.getOrderViaSODA(atpOrderPdb.getConnection(), orderId);
            String returnJSON = JsonUtils.writeValueAsString(order);
            System.out.println("OrderResource.showorder returnJSON:" + returnJSON);
            return Response.ok()
                    .entity(returnJSON)
                    .build();
        } catch (Exception e) {
            e.printStackTrace();
            return Response.serverError()
                    .entity("showorder orderid = " + orderId + " failed with exception:" + e.toString())
                    .build();
        }

    }


    @Operation(summary = "Deletes an order",
            description = "Deletes a previously-placed order")
    @APIResponses({
            @APIResponse(
                    responseCode = "200",
                    description = "Confirmation/result of the order deletion",
                    content = @Content(mediaType = "text/plain")
            )
    })
    @Path("/deleteorder")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response deleteorder(
            @Parameter(description = "The order ID for the order",
                    required = true,
                    example = "1",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("orderid") String orderId) {
        System.out.println("--->deleteorder for orderId:" + orderId);
        String returnString = "orderId = " + orderId + "<br>";
        try {
            returnString += orderServiceEventProducer.deleteOrderViaSODA(atpOrderPdb, orderId);
            return Response.ok()
                    .entity(returnString)
                    .build();
        } catch (Exception e) {
            e.printStackTrace();
            return Response.ok()
                    .entity("orderid = " + orderId + " failed with exception:" + e.toString())
                    .build();
        }
    }

    @Operation(summary = "Deletes all orders",
            description = "Deletes all previously-placed orders")
    @APIResponses({
            @APIResponse(
                    responseCode = "200",
                    description = "Confirmation/result of the order deletion",
                    content = @Content(mediaType = "application/json")
            )
    })
    @Path("/deleteallorders")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response deleteallorders() {
        System.out.println("--->deleteallorders");
        try {
            return Response.ok()
                    .entity(orderServiceEventProducer.dropOrderViaSODA(atpOrderPdb))
                    .build();
        } catch (Exception e) {
            e.printStackTrace();
            return Response.ok()
                    .entity("deleteallorders failed with exception:" + e.toString())
                    .build();
        }
    }


    @Path("/ordersetlivenesstofalse")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response ordersetlivenesstofalse() {
        liveliness = false;
        return Response.ok()
                .entity("order liveness set to false - OKE should restart the pod due to liveness probe")
                .build();
    }

    @Path("/ordersetreadinesstofalse")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response ordersetreadinesstofalse() {
        liveliness = false;
        return Response.ok()
                .entity("order readiness set to false")
                .build();
    }

    @Path("/startCPUStress")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response startCPUStress() {
        System.out.println("--->startCPUStress...");
        orderServiceCPUStress.start();
        return Response.ok()
                .entity("CPU stress started")
                .build();
    }

    @Path("/stopCPUStress")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response stopCPUStress() {
        System.out.println("--->stopCPUStress...");
        orderServiceCPUStress.stop();
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
                .entity("order crashAfterInsert set")
                .build();
    }

    @Path("/crashAfterInventoryMessageReceived")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response crashAfterInventoryMessageReceived() {
        crashAfterInventoryMessageReceived = true;
        return Response.ok()
                .entity("order crashAfterInventoryMessageReceived set")
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