/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.txeventq.okafka.service;


import com.oracle.developers.txeventq.okafka.config.data.LabEventData;
import com.oracle.developers.txeventq.okafka.config.data.LabResponseData;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.atomic.AtomicLong;

@RestController
public class OKafkaProducerServiceController {
    private static final Logger LOG = LoggerFactory.getLogger(OKafkaProducerServiceController.class);

    private final AtomicLong counter = new AtomicLong();

    private final OKafkaEventProducer eventProducer;

    public OKafkaProducerServiceController(OKafkaEventProducer eventProducer) {
        this.eventProducer = eventProducer;
    }

    @PostMapping(path = "/placeMessage", produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseBody
    public LabResponseData placeMessage(@RequestBody LabEventData newEvent) {
        Long id = counter.getAndIncrement();
        newEvent.setId(id.toString());

        LOG.info("placeMessage: id {}, message {} ", newEvent.getId(), newEvent.getMessage());

        String statusMessage = "Successful";

        LabResponseData response = new LabResponseData();
        response.setId(newEvent.getId());
        try {
            LOG.info("--->validateOrderAndSendEvent...");
            statusMessage= eventProducer.validateDataAndSendEvent(newEvent);
            LOG.info("--->Event posted with status {}.", statusMessage);
        } catch (Exception e) {
            LOG.error("Event not delivered with error {}", e.getCause());
            e.printStackTrace();
            statusMessage = "Failed";
        } finally {
            response.setStatusMessage(statusMessage);
        }

        LOG.debug("Response Message {}", response);
        return response;
    }

}
