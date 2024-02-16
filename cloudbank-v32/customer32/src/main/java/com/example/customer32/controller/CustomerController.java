// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32.controller;

import java.net.URI;
import java.util.List;
import java.util.Optional;

import com.example.customer32.model.Customer;
import com.example.customer32.service.CustomerService;
import io.swagger.v3.oas.annotations.Operation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@Slf4j
@RequestMapping("/api/v2")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    /**
     * Find all customers.
     * curl -i -X GET 'http://localhost:9090/api/v2/customer'
     * @return All customers from CUSTOMERS32 table.
     */
    @GetMapping("/customer")
    @ResponseStatus(HttpStatus.OK)
    @Operation(summary = "Find all customers")
    List<Customer> findAll() {
        return customerService.findAll();
    }

    /**
     * Find a customer by name.
     * curl -i -X GET 'http://localhost:9090/api/v2/customer/name/Walsh%20Group'
     * @param name Customer name.
     * @return Customer with the name from CUSTOMERS32 table if found and 200. If not 204.
     */
    @GetMapping("/customer/name/{name}")
    @Operation(summary = "Find a customer by name")
    ResponseEntity<Customer> findByCustomerByName(@PathVariable String name) {
        Optional<Customer> customer = customerService.findByCustomerByName(name);
        try {
            return customer.map(customers -> new ResponseEntity<>(customers, HttpStatus.OK))
                    .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Find customer by id.
     * curl -i -X GET 'http://localhost:9090/api/v2/customer/mcoleiroj'
     * @param id Customer id.
     * @return Customer with id from CUSTOMERS32 table if found and 200. If not 204.
     */
    @GetMapping("/customer/{id}")
    @Operation(summary = "Find customer by id")
    ResponseEntity<Customer> findCustomerById(@PathVariable String id) {
        Optional<Customer> customer = customerService.findCustomerById(id);
        try {
            return customer.map(customers -> new ResponseEntity<>(customers, HttpStatus.OK))
                    .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Find customer by email.
     * curl -i -X GET 'http://localhost:9090/api/v2/customer/email/cgoodhallj%40google.it'
     * @param email Customer email.
     * @return Customer with email from CUSTOMERS32 table if found and 201. If not 204.
     */
    @GetMapping("/customer/email/{email}")
    @Operation(summary = "Find customer by email")
    ResponseEntity<Customer> findCustomerByEmail(@PathVariable String email) {
        Optional<Customer> customer = customerService.findCustomerByEmail(email);
        try {
            return customer.map(customers -> new ResponseEntity<>(customers, HttpStatus.OK))
                    .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Create a customer.
     * curl -i -X POST 'http://localhost:9090/api/v2/customer' \
     * -H 'Content-Type: application/json' \
     * -d '{"id": "andyt", "name": "andytael", "email": "andy@andy.com"}'
     * @param customer Customer object.
     * @return Location of customer created and 201 else 204.
     */
    @PostMapping("/customer")
    @Operation(summary = "Create a customer")
    ResponseEntity<Object> createCustomer(@RequestBody Customer customer) {

        var retValue = customerService.createCustomer(customer);
        log.debug("createCustomer -- retValue : " + retValue);
        if (retValue == 1) {
            URI location = ServletUriComponentsBuilder
                    .fromCurrentRequest()
                    .path("/{id}")
                    .buildAndExpand(customer.id())
                    .toUri();
            log.debug("URI : " + location);
            return ResponseEntity.created(location).build();
        } else {
            return new ResponseEntity<>(null, HttpStatus.NO_CONTENT);
        }
    }

    /**
     * Update a customer.
     * curl -i -X PUT "http://localhost:8080/api/v2/customer/{id}}" \ \
     * -H 'Content-Type: application/json' \
     * -d '{"id": "wgeorgiev2r", "name": "andytael", "email": "andy@andy.com"}'
     * @param id Customer id to update
     * @param customer Customer object to update.
     * @return Returns 200 if customer is updated else 204.
     */
    @PutMapping("/customer/{id}")
    @Operation(summary = "Update a customer")
    ResponseEntity<Object> updateCustomer(@RequestBody Customer customer, @PathVariable String id) {
        log.debug("updateCustomer" + customer + " " + id);
        var retValue = customerService.updateCustomer(customer, id);
        log.debug("updateCustomer -- retValue : " + retValue);
        if (retValue == 1) {
            return new ResponseEntity<>(null, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(null, HttpStatus.NO_CONTENT);
        }
    }

    /**
     * Delete a customer.
     * curl -i -X DELETE 'http://localhost:9090/api/v2/customer/andyt'
     * @param id Customer id to delete.
     * @return 200 if customer is deleted else 204.
     */
    @DeleteMapping("/customer/{id}")
    @Operation(summary = "Delete a customer")
    ResponseEntity<Object> deleteCustomer(@PathVariable String id) {
        var retValue = customerService.deleteCustomer(id);
        log.debug("deleteCustomer -- retValue : " + retValue);
        if (retValue == 1) {
            return new ResponseEntity<>(null, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(null, HttpStatus.NO_CONTENT);
        }
    }
}

