/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import io.helidon.common.configurable.Resource;
import io.helidon.security.Security;
import io.helidon.security.SecurityContext;
import io.helidon.security.annotations.Authenticated;
import io.helidon.security.annotations.Authorized;
import io.opentracing.Span;
import io.opentracing.Tracer;
import org.eclipse.microprofile.auth.LoginConfig;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.metrics.annotation.Counted;
import org.eclipse.microprofile.metrics.annotation.Timed;
import org.eclipse.microprofile.opentracing.Traced;

import javax.annotation.security.DeclareRoles;
import javax.annotation.security.RolesAllowed;
import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.io.IOException;
import java.net.URLEncoder;

//import javax.annotation.security.*;
//import javax.ws.rs.*;


@Path("/")
@ApplicationScoped
@Traced
@Authenticated //just this for OIDC
@Authorized
@RolesAllowed("admin")
//@LoginConfig(authMethod = "MP-JWT", realmName = "jwt-jaspi")
//@DeclareRoles({"protected"})
public class FrontEndResource {

    @Inject
    private Tracer tracer;
    private Client client;

    @Inject
    private Security security;
    @Inject
    private SecurityContext securityContext;

    @Inject
    @ConfigProperty(name = "server.static.classpath.context")
    private String context;

    public FrontEndResource() {
        client = ClientBuilder.newBuilder()
                .build();
    }
    /* -------------------------------------------------------
     * JET UI Entry point
     * -------------------------------------------------------*/

    @Path("/test")
    @GET
    @Produces(MediaType.TEXT_HTML)
    public String test(@Context SecurityContext securityContext) {
        System.out.println("FrontEndResource auth will redirect to homepage securityContext.userName():" + securityContext.userName());
        return "Test";
    }

    @Path("/")
    @GET
    @Produces(MediaType.TEXT_HTML)
    public String home(@Context SecurityContext securityContext) {
        System.out.println("homepage securityContext.userName():" + securityContext.userName());
        String indexFile = Resource.create("web/index.html").string();
        return indexFile;
    }

    @Path("/spatial")
    @GET
    @Produces(MediaType.TEXT_HTML)
    public String spatial() {
        String indexFile = Resource.create("web/spatial.html").string();
        return indexFile;
    }


    /* -------------------------------------------------------
     * JET UI supporting endpoints to return the various static
     * resources used by the UI
     * -------------------------------------------------------*/

    @Path("/styles")
    @GET
    @Produces("text/css")
    public String uiStyles() {
        return Resource.create("web/styles.css").string();
    }

    @Path("/img")
    @GET
    @Produces("image/png")
    public Response uiImage(@QueryParam("name") String imageName) {
        try {
            return Response.ok(Resource.create("web/images/" + imageName + ".png").stream()).build();
        } catch (Exception e) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @Path("/logo")
    @GET
    @Produces("image/svg+xml")
    public Response logoImage() {
        try {
            return Response.ok(Resource.create("web/images/oracle-logo-dark.svg").stream()).build();
        } catch (Exception e) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @Path("/sushi")
    @GET
    @Produces("image/svg+xml")
    public Response sushi() {
        try {
            return Response.ok(Resource.create("web/images/sushi.svg").stream()).build();
        } catch (Exception e) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @Path("/pizza")
    @GET
    @Produces("image/svg+xml")
    public Response pizza() {
        try {
            return Response.ok(Resource.create("web/images/pizza.svg").stream()).build();
        } catch (Exception e) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @Path("/burger")
    @GET
    @Produces("image/svg+xml")
    public Response burger() {
        try {
            return Response.ok(Resource.create("web/images/burger.svg").stream()).build();
        } catch (Exception e) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("{path: css/.*}")
    public Response cssResources(@PathParam("path") final String path) {
        System.out.println("handling CSS assets: " + path);
        try {
            return Response.ok(Resource.create(String.format("web/%s", path)).stream()).build();
        } catch (Exception e) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    @Path("{path: js/.*}")
    public Response jsResources(@PathParam("path") final String path) {
        System.out.println("handling JS assets: " + path);
        try {
            return Response.ok(Resource.create(String.format("web/%s", path)).stream()).build();
        } catch (Exception e) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    /* -------------------------------------------------------------------------
     * JET UI supporting wrapper endpoints - we could make these calls
     * Directly from the JS code, however, this way, the UI is abstracted from
     * having to know ultimately where the backend services are living
     * -------------------------------------------------------------------------*/
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Path("/placeorder")
    @Traced(operationName = "Frontend.placeOrder")
    @Timed(name = "frontend_placeOrder_timed") //length of time of an object
    @Counted(name = "frontend_placeOrder_counted") //amount of invocations
    public String placeorder(Command command) {
        try {
            System.out.println("FrontEndResource.serviceName " + command.serviceName);
            System.out.println("FrontEndResource.commandName " + command.commandName);
            String json = makeRequest("http://order.msdataworkshop:8080/placeOrder?orderid=" + command.orderId +
                    "&itemid=" + command.orderItem + "&deliverylocation=" + URLEncoder.encode(command.deliverTo, "UTF-8"));
            System.out.println("FrontEndResource.placeorder json:" + json);
            if (json.indexOf("fail") > -1) { // we return 200 regardless and check for "fail"
                if (json.indexOf("SQLIntegrityConstraintViolationException") > -1)
                    return asJSONMessage("SQLIntegrityConstraintViolationException. Delete All Orders or use a different order id to avoid dupes.");
                else return asJSONMessage(json);
            }
            System.out.println("FrontEndResource.placeorder complete, now show order...");
            json = makeRequest("http://order.msdataworkshop:8080/showorder?orderid=" + command.orderId);
            System.out.println("FrontEndResource.placeorder showorder json:" + json);
            return json;
        } catch (IOException e) {
            e.printStackTrace();
            return "\"error\":\"" + e.getMessage() + "\"";
        }

    }

    int autoincrementorderid = 1;
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Path("/placeorderautoincrement")
    @Traced(operationName = "Frontend.placeOrder")
    @Timed(name = "frontend_placeOrder_timed") //length of time of an object
    @Counted(name = "frontend_placeOrder_counted") //amount of invocations
    public String placeorderautoincrement(Command command) {
        command.orderId = autoincrementorderid++;
        return placeorder(command);
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Traced(operationName = "FrontEnd.command")
    @Path("/command")
    public String command(Command command) {
        boolean isOrderBasedCommand = command.serviceName.equals("order") && command.orderId != -1;
        if (isOrderBasedCommand) {
            Span activeSpan = tracer.buildSpan("orderDetail").asChildOf(tracer.activeSpan()).start();
            activeSpan.setTag("orderid", command.orderId);
            activeSpan.setBaggageItem("command.orderId", "" + command.orderId);
            activeSpan.finish();
        }
        boolean isSupplierCommand = command.serviceName.equals("supplier");
        boolean isHealthCommand = command.commandName.indexOf("health") > -1;
        String urlString = "http://" + command.serviceName + ".msdataworkshop:8080/" + command.commandName +
                (isOrderBasedCommand ? "?orderid=" + command.orderId : "") +
                (isSupplierCommand ? "?itemid=" + command.orderItem : "");
        System.out.println("FrontEndResource.command url:" + urlString);
        try {
            String response = makeRequest(urlString);
            String returnString = isOrderBasedCommand || isHealthCommand ? response : asJSONMessage(response);
            System.out.println("FrontEndResource.command url:" + urlString + "  returnString:" + returnString);
            return returnString;
        } catch (Exception e) {
            e.printStackTrace();
            return asJSONMessage(e);
        }
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.TEXT_PLAIN)
    @Traced(operationName = "FrontEnd.getmetrics")
    @Path("/getmetrics")
    //not to be confused with the /metrics of this frontend service,
    // this is a call through to a service (can be any service but the frontend only calls order service) to get and display it's metrics
    public String getMetrics(Command command) {
        String urlString = "http://" + command.serviceName + ".msdataworkshop:8080/" + command.commandName;
        System.out.println("FrontEndResource.getMetrics url:" + urlString);
        try {
            String response = makeRequest(urlString);
            System.out.println("FrontEndResource.getMetrics url:" + urlString + "  returnString:" + response);
            return response;
        } catch (Exception e) {
            e.printStackTrace();
            return asJSONMessage(e);
        }
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.TEXT_PLAIN)
    @Traced(operationName = "FrontEnd.openAPI")
    @Path("/openAPI")
    public String openAPI(Command command) {
        String urlString = "http://" + command.serviceName + ".msdataworkshop:8080/" + command.commandName;
        System.out.println("FrontEndResource.openAPI url:" + urlString);
        try {
            String response = makeRequest(urlString);
            System.out.println("FrontEndResource.openAPI url:" + urlString + "  returnString:" + response);
            return response;
        } catch (Exception e) {
            e.printStackTrace();
            return asJSONMessage(e);
        }
    }

    private String asJSONMessage(Object e) {
        FrontEndResponse frontEndResponse = new FrontEndResponse();
        frontEndResponse.message = e.toString();
        return JsonUtils.writeValueAsString(frontEndResponse);
    }

    private String makeRequest(String url) throws IOException {
        System.out.println("FrontEndResource.makeRequest url.toString():" + url);
        Response response = client.target(url).request().get();
        String entity = response.readEntity(String.class);
        System.out.println("OrderResource.placeOrder response from inventory:" + entity);
        return entity;
    }


}
