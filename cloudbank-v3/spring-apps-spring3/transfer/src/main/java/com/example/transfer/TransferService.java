// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.transfer;

import java.net.URI;

import com.oracle.microtx.springboot.lra.annotation.Compensate;
import com.oracle.microtx.springboot.lra.annotation.Complete;
import com.oracle.microtx.springboot.lra.annotation.LRA;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import static com.oracle.microtx.springboot.lra.annotation.LRA.LRA_HTTP_CONTEXT_HEADER;

@RestController
@RequestMapping("/")
@Slf4j
public class TransferService {

    public static final String TRANSFER_ID = "TRANSFER_ID";

    @Value("${account.withdraw.url}") URI withdrawUri;
    @Value("${account.deposit.url}") URI depositUri;
    @Value("${transfer.cancel.url}") URI transferCancelUri;
    @Value("${transfer.cancel.process.url}") URI transferProcessCancelUri;
    @Value("${transfer.confirm.url}") URI transferConfirmUri;
    @Value("${transfer.confirm.process.url}") URI transferProcessConfirmUri;

    /**
     * Ping method.
     * @return Http OK.
     */
    @GetMapping("/hello")
    public ResponseEntity<String> ping() {
        log.info("Say Hello!");
        return ResponseEntity.ok("");
    }

    /**
     * Transfer amount between two accounts.
     * @param fromAccount From an account
     * @param toAccount To an account
     * @param amount Amount to transfer
     * @param lraId LRA Id
     * @return TO-DO
     */
    @PostMapping("/transfer")
    @LRA(value = LRA.Type.REQUIRES_NEW, end = false)
    public ResponseEntity<String> transfer(@RequestParam("fromAccount") long fromAccount,
            @RequestParam("toAccount") long toAccount,
            @RequestParam("amount") long amount,
            @RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        if (lraId == null) {
            return new ResponseEntity<>("Failed to create LRA", HttpStatus.INTERNAL_SERVER_ERROR);
        }
        log.info("Started new LRA/transfer Id: " + lraId);

        boolean isCompensate = false;
        String returnString = "";

        // perform the withdrawal
        returnString += withdraw(lraId, fromAccount, amount);
        log.info(returnString);
        if (returnString.contains("succeeded")) {
            // if it worked, perform the deposit
            returnString += " " + deposit(lraId, toAccount, amount);
            log.info(returnString);
            if (returnString.contains("failed")) {
                isCompensate = true; // deposit failed
            }
        } else {
            isCompensate = true; // withdraw failed
        }
        log.info("LRA/transfer action will be " + (isCompensate ? "cancel" : "confirm"));

        // call complete or cancel based on outcome of previous actions
        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_PLAIN);
        headers.set(TRANSFER_ID, lraId);
        HttpEntity<String> request = new HttpEntity<String>("", headers);

        ResponseEntity<String> response = restTemplate.postForEntity(
            (isCompensate ? transferCancelUri : transferConfirmUri).toString(), 
            request, 
            String.class);

        returnString += response.getBody();

        // return status
        return ResponseEntity.ok("transfer status:" + returnString);

    }

    private String withdraw(String lraId, long accountId, long amount) {
        log.info("withdraw accountId = " + accountId + ", amount = " + amount);
        log.info("withdraw lraId = " + lraId);
        
        UriComponentsBuilder builder = UriComponentsBuilder.fromUri(withdrawUri)
            .queryParam("accountId", accountId)
            .queryParam("amount", amount);

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_PLAIN);
        headers.set(LRA_HTTP_CONTEXT_HEADER, lraId.toString());
        HttpEntity<String> request = new HttpEntity<String>("", headers);

        ResponseEntity<String> response = restTemplate.postForEntity(
            builder.buildAndExpand().toUri(), 
            request, 
            String.class);

        return response.getBody();
    }

    private String deposit(String lraId, long accountId, long amount) {
        log.info("deposit accountId = " + accountId + ", amount = " + amount);
        log.info("deposit lraId = " + lraId);
        
        UriComponentsBuilder builder = UriComponentsBuilder.fromUri(depositUri)
            .queryParam("accountId", accountId)
            .queryParam("amount", amount);

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_PLAIN);
        headers.set(LRA_HTTP_CONTEXT_HEADER, lraId.toString());
        HttpEntity<String> request = new HttpEntity<String>("", headers);

        ResponseEntity<String> response = restTemplate.postForEntity(
            builder.buildAndExpand().toUri(), 
            request, 
            String.class);

        return response.getBody();
    }

    @PostMapping("/processconfirm")
    @LRA(value = LRA.Type.MANDATORY)
    public ResponseEntity<String> processconfirm(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        log.info("Process confirm for transfer : " + lraId);
        return ResponseEntity.ok("");
    }

    @PostMapping("/processcancel")
    @LRA(value = LRA.Type.MANDATORY, cancelOn = HttpStatus.OK)
    public ResponseEntity<String> processcancel(@RequestHeader(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        log.info("Process cancel for transfer : " + lraId);
        return ResponseEntity.ok("");
    }

    /**
     * Confirm a transfer.
     * @param transferId Transfer Id
     * @return TO-DO
     */
    @PostMapping("/confirm")
    @Complete
    @LRA(value = LRA.Type.NOT_SUPPORTED)
    public ResponseEntity<String> confirm(@RequestHeader(TRANSFER_ID) String transferId) {
        log.info("Received confirm for transfer : " + transferId);

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_PLAIN);
        headers.set(LRA_HTTP_CONTEXT_HEADER, transferId);
        HttpEntity<String> request = new HttpEntity<String>("", headers);

        ResponseEntity<String> response = restTemplate.postForEntity(
            transferProcessConfirmUri, 
            request, 
            String.class);

        return ResponseEntity.ok(response.getBody());
    }

    /**
     * Cancel a transfer.
     * @param transferId Transfer Id
     * @return TO-DO
     */
    @PostMapping("/cancel")
    @Compensate
    @LRA(value = LRA.Type.NOT_SUPPORTED, cancelOn = HttpStatus.OK)
    public ResponseEntity<String> cancel(@RequestHeader(TRANSFER_ID) String transferId) {
        log.info("Received cancel for transfer : " + transferId);

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_PLAIN);
        headers.set(LRA_HTTP_CONTEXT_HEADER, transferId);
        HttpEntity<String> request = new HttpEntity<String>("", headers);

        ResponseEntity<String> response = restTemplate.postForEntity(
            transferProcessCancelUri, 
            request, 
            String.class);

        return ResponseEntity.ok(response.getBody());
    }

}