package io.micronaut.data.examples;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micronaut.context.event.StartupEvent;
import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.*;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.annotation.Controller;
import io.micronaut.runtime.event.annotation.EventListener;

import javax.inject.Inject;
import javax.sql.DataSource;

@Controller("/inventory")
public class InventoryController {

    @Inject
    DataSource atpInventoryPDB;

    private final InventoryEventProducer inventoryEventProducer;
    public InventoryController(InventoryEventProducer inventoryEventProducer) {
        this.inventoryEventProducer = inventoryEventProducer;
    }

    //todo explore use of https://github.com/micronaut-projects/micronaut-jms/blob/f49e7a327b680cb94a4150a739aac58371f643b9/jms-core/src/main/java/io/micronaut/jms/bind/JMSArgumentBinderRegistry.java
    // in conjunction with the @JMSListener already implemented
    @EventListener
    void onStartup(StartupEvent event) {
        System.out.println("InventoryController.onStartup");
        new Thread(new InventoryServiceOrderEventConsumer(atpInventoryPDB)).start();
    }

    @Post(value = "/send", produces = MediaType.APPLICATION_JSON)
    public HttpResponse send(@Body Inventory message) throws JsonProcessingException {
        inventoryEventProducer.send(new ObjectMapper().writeValueAsString(message));
        return HttpResponse.ok();
    }


    @Get(value = "/addInventory",  produces="text/plain")
    public HttpResponse addInventory() {
        System.out.println("InventoryController.addInventory for atpInventoryPDB:" + atpInventoryPDB);
        return HttpResponse.ok();
    }


}



