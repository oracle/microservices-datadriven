/*

 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import java.util.HashMap;
import java.util.Map;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.context.Initialized;
import javax.enterprise.event.Observes;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

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
public class KafkaMongoOrderResource {

    @Inject
    private Tracer tracer;

    KafkaMongoDBOrderProducer orderServiceEventProducer = new KafkaMongoDBOrderProducer();
    final static String orderTopicName = "order.topic";
    final static String inventoryTopicName = "inventory.topic";
    static boolean liveliness = true;
    static boolean crashAfterInsert = false;
    static boolean crashAfterInventoryMessageReceived = false;
    static boolean readiness = true;
    private static String lastContainerStartTime;
    Map<String, OrderDetail> cachedOrders = new HashMap<>();

    @Path("/lastContainerStartTime")
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public Response lastContainerStartTime() {
        System.out.println("--->lastContainerStartTime...");
        return Response.ok()
                .entity("lastContainerStartTime = " + lastContainerStartTime)
                .build();
    }

    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws Exception {
        System.out.println("KafkaMongoOrderResource.init " + init);
        startEventConsumer();
        lastContainerStartTime = new java.util.Date().toString();
        System.out.println("____________________________________________________");
        System.out.println("----------->KafkaMongoOrderResource (container) starting at: " + lastContainerStartTime);
        System.out.println("____________________________________________________");
    }

    private void startEventConsumer() {
        System.out.println("OrderResource.startEventConsumerIfNotStarted startEventConsumer...");
        KafkaMongoOrderEventConsumer orderServiceEventConsumer = new KafkaMongoOrderEventConsumer();
        new Thread(orderServiceEventConsumer).start();
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
    @Timed(name = "placeOrder_timed") //length of time of an object
    @Counted(name = "placeOrder_counted") //amount of invocations
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
        OrderDetail orderDetail = new OrderDetail();
        orderDetail.setOrderId(orderid);
        orderDetail.setItemId(itemid);
        orderDetail.setOrderStatus("pending");
        orderDetail.setDeliveryLocation(deliverylocation);
        cachedOrders.put(orderid, orderDetail);

        Span activeSpan = tracer.buildSpan("orderDetail").asChildOf(tracer.activeSpan()).start();
        activeSpan.log("begin placing order"); // logs are for a specific moment or event within the span (in contrast to tags which should apply to the span regardless of time).
        activeSpan.setTag("orderid", orderid); //tags are annotations of spans in order to query, filter, and comprehend trace data
        activeSpan.setTag("itemid", itemid);
        activeSpan.setTag("db.user", "mongodb"); // https://github.com/opentracing/specification/blob/master/semantic_conventions.md
        activeSpan.setBaggageItem("sagaid", "testsagaid" + orderid); //baggage is part of SpanContext and carries data across process boundaries for access throughout the trace
        activeSpan.setBaggageItem("orderid", orderid);

        try {
            System.out.println("--->insertOrderAndSendEvent..." +
                    orderServiceEventProducer.updateDataAndSendEvent(orderid, itemid, deliverylocation));
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
                .entity("orderid = " + orderid + " orderstatus = " + orderDetail.getOrderStatus() + " order placed")
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
    public Response showorder(
            @Parameter(description = "The order ID for the order",
                    required = true,
                    example = "1",
                    schema = @Schema(type = SchemaType.STRING))
            @QueryParam("orderid") String orderId) {
        System.out.println("--->showorder (via JSON/SODA query) for orderId:" + orderId);
        try {
            Order order = orderServiceEventProducer.getOrderFromMongoDB(orderId);
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
            returnString += orderServiceEventProducer.deleteOrderFromMongoDB(orderId);
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
                    .entity(orderServiceEventProducer.dropOrderFromMongoDB())
                    .build();
        } catch (Exception e) {
            e.printStackTrace();
            return Response.ok()
                    .entity("deleteallorders failed with exception:" + e.toString())
                    .build();
        }
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


}