package com.cloudbank.authservice.controllers;


import com.cloudbank.authservice.entity.TransferRequestBody;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.net.URI;

@RestController
@RequestMapping("/api/transfer")
public class TransferController {

    @Autowired
    private Environment environment;

    /**
     * Makes a post request to transfer funds depending on the source
     * @param request body of the request (TransferRequestBody type)
     * @return JSON string retrieved from the specific bank endpoint
     * @throws Exception
     */
    @PostMapping("/transferfunds")
    public String makeTransferRequest(@RequestBody TransferRequestBody request) throws Exception {

        String endpoint = request.getFromBank().equals("banka") ?
                environment.getProperty("cloudbank.ep.banka") :
                environment.getProperty("cloudbank.ep.bankb");


        assert endpoint != null;
        WebClient webClient = WebClient.create();

        String response = webClient.post()
                .uri(new URI(endpoint + "/transferfunds"))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .body(BodyInserters.fromPublisher(Mono.just(request), TransferRequestBody.class))
                .retrieve()
                .bodyToMono(String.class)
                .block();
        System.out.println(response);
        return response;

    }

}
