// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32.controller;

import java.util.List;
import java.util.Optional;

import com.example.customer32.model.Customer;
import com.example.customer32.service.CustomerService;
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

@RestController
@RequestMapping("/api/cust")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    /**
     * FInd all customers.
     * @return All customers from CUSTOMERS32 table.
     */
    @GetMapping("/customer")
    @ResponseStatus(HttpStatus.OK)
    List<Customer> findAll() {
        return customerService.findAll();
    }

    /**
     * Find a customer by name.
     * @param name Customer name.
     * @return Customer with the name from CUSTOMERS32 table.
     */
    @GetMapping("/customer/name/{name}")
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
     * @param id Custmer id.
     * @return Customer with id from CUSTOMERS32 table.
     */
    @GetMapping("/customer/{id}")
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
     * @param email Customer email.
     * @return Customer with email from CUSTOMERS32 table.
     */
    @GetMapping("/customer/byemail/{email}")
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
     * @param customer Customer object.
     */
    @PostMapping("/customer")
    @ResponseStatus(HttpStatus.CREATED)
    void createCustomer(@RequestBody Customer customer) {
        customerService.createCustomer(customer);
    }

    /**
     * Update a customer.
     * @param customer Customer object to update.
     * @return Returns 0 if successful.
     */
    @PutMapping("/customer")
    ResponseEntity<Object> updateCustomer(@RequestBody Customer customer) {
        var retValue = customerService.updateCustomer(customer);
        if (retValue == 0) {
            return new ResponseEntity<>(null, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(null, HttpStatus.NO_CONTENT);
        }
    }

    /**
     * Delete a customer.
     * @param id Customer id to delete.
     * @return 0 if successful.
     */
    @DeleteMapping("/customer/{id}")
    ResponseEntity<Object> deleteCustomer(@PathVariable String id) {
        var retValue = customerService.deleteCustomer(id);
        if (retValue == 0) {
            return new ResponseEntity<>(null, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(null, HttpStatus.NO_CONTENT);
        }
    }
}

