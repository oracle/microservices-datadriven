// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.customer.controller;

import com.example.customer.model.Customers;
import com.example.customer.repository.CustomersRepository;

import lombok.extern.slf4j.Slf4j;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1")
@Slf4j
public class CustomerController {
    final CustomersRepository customersRepository;

    public CustomerController(CustomersRepository customersRepository) {
        this.customersRepository = customersRepository;
    }

    @ResponseStatus(HttpStatus.OK)
    @GetMapping("/customer")
    public List<Customers> findAll() {
        log.info("CUSTOMER: findAll");
        return customersRepository.findAll();
    }

    @ResponseStatus(HttpStatus.OK)
    @GetMapping("/customer/name/{customerName}")
    public List<Customers> findByCustomerByName(@PathVariable String customerName) {
        log.info("CUSTOMER: findByCustomerByName");
        return customersRepository.findByCustomerNameIsContaining(customerName);
    }

    // Get Customer with specific ID
    @GetMapping("/customer/{id}")
    public ResponseEntity<Customers> getCustomerById(@PathVariable("id") String id) {
        log.info("CUSTOMER: getCustomerById");
        Optional<Customers> customerData = customersRepository.findById(id);
        try {
            return customerData.map(customers -> new ResponseEntity<>(customers, HttpStatus.OK))
                    .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // get customer by email
    @GetMapping("/customer/byemail/{email}")
    public List<Customers> getCustomerByEmail(@PathVariable("email") String email) {
        log.info("CUSTOMER: getCustomerByEmail");
        return customersRepository.findByCustomerEmailIsContaining(email);
    }

    @PostMapping("/customer")
    public ResponseEntity<Customers> createCustomer(@RequestBody Customers customer) {
        log.info("CUSTOMER: createCustomer");
        try {
            Customers _customer = customersRepository.save(new Customers(
                    customer.getCustomerId(),
                    customer.getCustomerName(),
                    customer.getCustomerEmail(),
                    customer.getCustomerOtherDetails()));
            return new ResponseEntity<>(_customer, HttpStatus.CREATED);

        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // Update a specific Customer (ID)
    @PutMapping("/customer/{id}")
    public ResponseEntity<Customers> updateCustomer(@PathVariable("id") String id, @RequestBody Customers customer) {
        log.info("CUSTOMER: updateCustomer");
        Optional<Customers> customerData = customersRepository.findById(id);
        try {
            if (customerData.isPresent()) {
                Customers _customer = customerData.get();
                _customer.setCustomerName(customer.getCustomerName());
                _customer.setCustomerEmail(customer.getCustomerEmail());
                _customer.setCustomerOtherDetails(customer.getCustomerOtherDetails());
                return new ResponseEntity<>(customersRepository.save(_customer), HttpStatus.OK);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        }
        catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // Delete a specific customer (ID)
    @DeleteMapping("/customer/{customerId}")
    public ResponseEntity<HttpStatus> deleteCustomer(@PathVariable("customerId") String customerId) {
        log.info("CUSTOMER: deleteCustomer");
        try {
            customersRepository.deleteById(customerId);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PostMapping("/customer/applyLoan/{amount}")
    public ResponseEntity<HttpStatus> applyForLoan(@PathVariable ("amount") long amount) {
        log.info("CUSTOMER: applyForLoan");
        try {
            // Check Credit Rating
            // Amount vs Rating approval?
            // Create Account
            // Update Account Balance
            // Notify
            return new ResponseEntity<>(HttpStatus.I_AM_A_TEAPOT);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
