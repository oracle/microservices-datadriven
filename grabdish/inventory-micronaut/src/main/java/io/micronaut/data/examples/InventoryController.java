package io.micronaut.data.examples;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.*;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.annotation.Controller;

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



