// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.transfer;

import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_CONTEXT_HEADER;

import java.net.URI;
import java.net.URISyntaxException;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import lombok.extern.slf4j.Slf4j;

import org.eclipse.microprofile.lra.annotation.ws.rs.LRA;

import io.narayana.lra.Current;

@ApplicationScoped
@Path("/")
@Slf4j
public class TransferService {

    public static final String TRANSFER_ID = "TRANSFER_ID";
    private URI withdrawUri;
    private URI depositUri;
    private URI transferCancelUri;
    private URI transferConfirmUri;
    private URI transferProcessCancelUri;
    private URI transferProcessConfirmUri;

    @PostConstruct
    private void initController() {
        try {
            withdrawUri = new URI(ApplicationConfig.accountWithdrawUrl);
            depositUri = new URI(ApplicationConfig.accountDepositUrl);
            transferCancelUri = new URI(ApplicationConfig.transferCancelURL);
            transferConfirmUri = new URI(ApplicationConfig.transferConfirmURL);
            transferProcessCancelUri = new URI(ApplicationConfig.transferCancelProcessURL);
            transferProcessConfirmUri = new URI(ApplicationConfig.transferConfirmProcessURL);
        } catch (URISyntaxException ex) {
            throw new IllegalStateException("Failed to initialize " + TransferService.class.getName(), ex);
        }
    }

    @GET
    @Path("/hello")
    @Produces(MediaType.APPLICATION_JSON)
    public Response ping () throws NotFoundException {
        log.info("Say Hello!");
        return Response.ok().build();   
    }

    @POST
    @Path("/transfer")
    @Produces(MediaType.APPLICATION_JSON)
    @LRA(value = LRA.Type.REQUIRES_NEW, end = false)
    public Response transfer(@QueryParam("fromAccount") long fromAccount,
            @QueryParam("toAccount") long toAccount,
            @QueryParam("amount") long amount,
            @HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        if (lraId == null) {
            return Response.serverError().entity("Failed to create LRA").build();
        }
        log.info("Started new LRA/transfer Id: " + lraId);

        boolean isCompensate = false;
        String returnString = "";

        // perform the withdrawal
        returnString += withdraw(fromAccount, amount);
        log.info(returnString);
        if (returnString.contains("succeeded")) {
            // if it worked, perform the deposit
            returnString += " " + deposit(toAccount, amount);
            log.info(returnString);
            if (returnString.contains("failed"))
                isCompensate = true; // deposit failed
        } else
            isCompensate = true; // withdraw failed
        log.info("LRA/transfer action will be " + (isCompensate ? "cancel" : "confirm"));

        // call complete or cancel based on outcome of previous actions
        WebTarget webTarget = ClientBuilder.newClient().target(isCompensate ? transferCancelUri : transferConfirmUri);
        webTarget.request().header(TRANSFER_ID, lraId)
                .post(Entity.text("")).readEntity(String.class);

        // return status
        return Response.ok("transfer status:" + returnString).build();

    }

    private String withdraw(long accountId, long amount) {
        log.info("withdraw accountId = " + accountId + ", amount = " + amount);
        WebTarget webTarget = ClientBuilder.newClient().target(withdrawUri).path("/")
                .queryParam("accountId", accountId)
                .queryParam("amount", amount);
        URI lraId = Current.peek();
        log.info("withdraw lraId = " + lraId);
        String withdrawOutcome = webTarget.request().header(LRA_HTTP_CONTEXT_HEADER, lraId)
                .post(Entity.text("")).readEntity(String.class);
        return withdrawOutcome;
    }

    private String deposit(long accountId, long amount) {
        log.info("deposit accountId = " + accountId + ", amount = " + amount);
        WebTarget webTarget = ClientBuilder.newClient().target(depositUri).path("/")
                .queryParam("accountId", accountId)
                .queryParam("amount", amount);
        URI lraId = Current.peek();
        log.info("deposit lraId = " + lraId);
        String depositOutcome = webTarget.request().header(LRA_HTTP_CONTEXT_HEADER, lraId)
                .post(Entity.text("")).readEntity(String.class);
        ;
        return depositOutcome;
    }

    @POST
    @Path("/processconfirm")
    @Produces(MediaType.APPLICATION_JSON)
    @LRA(value = LRA.Type.MANDATORY)
    public Response processconfirm(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) throws NotFoundException {
        log.info("Process confirm for transfer : " + lraId);
        return Response.ok().build();
    }

    @POST
    @Path("/processcancel")
    @Produces(MediaType.APPLICATION_JSON)
    @LRA(value = LRA.Type.MANDATORY, cancelOn = Response.Status.OK)
    public Response processcancel(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) throws NotFoundException {
        log.info("Process cancel for transfer : " + lraId);
        return Response.ok().build();
    }

    @POST
    @Path("/confirm")
    @Produces(MediaType.APPLICATION_JSON)
    @LRA(value = LRA.Type.NOT_SUPPORTED)
    public Response confirm(@HeaderParam(TRANSFER_ID) String transferId) throws NotFoundException {
        log.info("Received confirm for transfer : " + transferId);
        String confirmOutcome = ClientBuilder.newClient().target(transferProcessConfirmUri).request()
                .header(LRA_HTTP_CONTEXT_HEADER, transferId)
                .post(Entity.text("")).readEntity(String.class);
        return Response.ok(confirmOutcome).build();
    }

    @POST
    @Path("/cancel")
    @Produces(MediaType.APPLICATION_JSON)
    @LRA(value = LRA.Type.NOT_SUPPORTED, cancelOn = Response.Status.OK)
    public Response cancel(@HeaderParam(TRANSFER_ID) String transferId) throws NotFoundException {
        log.info("Received cancel for transfer : " + transferId);
        String confirmOutcome = ClientBuilder.newClient().target(transferProcessCancelUri).request()
                .header(LRA_HTTP_CONTEXT_HEADER, transferId)
                .post(Entity.text("")).readEntity(String.class);
        return Response.ok(confirmOutcome).build();
    }

}