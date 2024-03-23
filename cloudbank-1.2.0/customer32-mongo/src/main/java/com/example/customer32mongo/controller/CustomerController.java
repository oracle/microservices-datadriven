// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32mongo.controller;

import java.net.URI;
import java.util.List;
import java.util.Optional;

import com.example.customer32mongo.model.Customer;
import com.example.customer32mongo.service.CustomerService;
import org.springframework.http.HttpHeaders;
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
@RequestMapping("/api/v1mongo")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    /**
     * Find all customers.
     * 
     * @return A list of all customers in the collection.
     */
    @GetMapping("/customer")
    @ResponseStatus(HttpStatus.OK)
    List<Customer> findAll() {
        return customerService.findAll();
    }

    /**
     * Find a customer by name.
     * 
     * @param name The name to search for.
     * @return Customer with the specified name, if found, and status 200.  If not, 204.
     */
    @GetMapping("/customer/name/{name}")
    public ResponseEntity<Customer> findCustomerByName(@PathVariable String name) {
        Optional<Customer> customer = customerService.findByCustomerName(name);
        try {
            return customer.map(customers -> new ResponseEntity<>(customers, HttpStatus.OK))
                    .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Find customer by id.
     * 
     * @param id The customer ID to search for.
     * @return Customer with the specified ID, if found, and status 200.  If not, 204.
     */
    @GetMapping("/customer/{id}")
    ResponseEntity<Customer> findCustomerById(@PathVariable String id) {
        Optional<Customer> customer = customerService.findByCustomerId(id);
        try {
            return customer.map(customers -> new ResponseEntity<>(customers, HttpStatus.OK))
            .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Find a customer by email.
     * 
     * @param email The name to search for.
     * @return Customer with the specified email, if found, and status 200.  If not, 204.
     */
    @GetMapping("/customer/email/{email}")
    public ResponseEntity<Customer> findCustomerByEmail(@PathVariable String email) {
        Optional<Customer> customer = customerService.findByCustomerEmail(email);
        try {
            return customer.map(customers -> new ResponseEntity<>(customers, HttpStatus.OK))
                    .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Create a customer.
     * 
     * @param customer The customer object
     * @return The created customer and location header with 201, else 204.
     */
    @PostMapping("/customer")
    ResponseEntity<Customer> createCustomer(@RequestBody Customer customer) {
        var result = customerService.createCustomer(customer);
        if (result != null) {
            URI location = ServletUriComponentsBuilder
                    .fromCurrentRequest()
                    .path("/{id}")
                    .buildAndExpand(customer.id)
                    .toUri();
            var headers = new HttpHeaders();
            headers.setLocation(location);
            return new ResponseEntity<>(result, headers, HttpStatus.CREATED);
        } else {
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        }
    }

    /**
     * Update a customer.
     * 
     * @param customer The customer to update.
     * @return The udpated customer with 200, else 204.
     */
    @PutMapping("/customer/{id}")
    ResponseEntity<Customer> updateCustomer(@RequestBody Customer customer, @PathVariable String id) {
        var result = customerService.updateCustomer(customer, id);
        if (result != null) {
            return new ResponseEntity<>(result, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        }
    }

    /**
     * Delete a customer.
     * 
     * Note that Mongo's delete API silently ignores if a document
     * with the specified ID is not found, so we just return OK no 
     * matter what happened.
     * 
     * @param id The ID of the customer to delete.
     * @return 200 OK.
     */
    @DeleteMapping("/customer/{id}")
    ResponseEntity<Customer> deleteCustomer(@PathVariable String id) {
        customerService.deleteCustomer(id);
        return new ResponseEntity<>(HttpStatus.OK);
    }

}
