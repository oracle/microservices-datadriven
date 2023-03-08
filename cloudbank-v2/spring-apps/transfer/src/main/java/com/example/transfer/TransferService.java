// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.transfer;

import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_CONTEXT_HEADER;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.enterprise.context.ApplicationScoped;
import javax.ws.rs.HeaderParam;
import javax.ws.rs.NotFoundException;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.client.Entity;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;

import org.eclipse.microprofile.lra.annotation.ws.rs.LRA;

import io.narayana.lra.Current;

@ApplicationScoped
@Path("/")
public class TransferService {

    private static final Logger log = Logger.getLogger(TransferService.class.getSimpleName());
    public static final String TRANSFER_ID = "TRANSFER_ID";
    private URI withdrawUri;
    private URI depositUri;
    private URI transferCancelUri;
    private URI transferConfirmUri;
    private URI transferProcessCancelUri;
    private URI transferProcessConfirmUri;

    @PostConstruct
    private void initController() {
        try { //todo get from Environment instead...
            withdrawUri = new URI(System.getenv("withdraw.account.service.url"));
            depositUri = new URI(System.getenv("deposit.account.service.url"));
        } catch (URISyntaxException ex) {
            throw new IllegalStateException("Failed to initialize " + TransferService.class.getName(), ex);
        }
    }

    @POST
    @Path("/transfer")
    @Produces(MediaType.APPLICATION_JSON)
    @LRA(value = LRA.Type.REQUIRES_NEW)
    public Response bookTrip(@QueryParam("fromAccount") String fromAccount,
                             @QueryParam("toAccount") String toAccount,
                             @QueryParam("amount") long amount,
                             @Context UriInfo uriInfo,
                             @HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId,
                             @Context ContainerRequestContext containerRequestContext)
    {
        if (lraId == null) {
            return Response.serverError().entity("Failed to create LRA").build();
        }
        log.info("Started new LRA : " + lraId);
        withdraw(fromAccount, amount);
        deposit(toAccount, amount);
        return Response.ok("transfer successful").build();

    }
    private String withdraw(String accountName, long depositAmount) {
        log.info("withdraw accountName = " + accountName + ", depositAmount = " + depositAmount);
        WebTarget webTarget =
                ClientBuilder.newClient().target(withdrawUri).path("/")
                        .queryParam("accountName", accountName)
                        .queryParam("withdrawAmount", depositAmount);
        String withdrawOutcome = webTarget.request().post(Entity.text("")).getEntity().toString();
        return withdrawOutcome;
    }
    private String deposit(String accountName, long depositAmount) {
        log.info("deposit accountName = " + accountName + ", depositAmount = " + depositAmount);
        WebTarget webTarget =
                ClientBuilder.newClient().target(depositUri).path("/")
                        .queryParam("accountName", accountName)
                        .queryParam("depositAmount", depositAmount);
        String withdrawOutcome = webTarget.request().post(Entity.text("")).getEntity().toString();
        return withdrawOutcome;
    }

}