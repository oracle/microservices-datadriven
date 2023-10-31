// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer.controller;

import java.util.List;
import java.util.Optional;

import com.example.customer.model.Customers;
import com.example.customer.repository.CustomersRepository;
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
@RequestMapping("/api/v1")
public class CustomerController {
    final CustomersRepository customersRepository;

    public CustomerController(CustomersRepository customersRepository) {
        this.customersRepository = customersRepository;
    }

    @ResponseStatus(HttpStatus.OK)
    @GetMapping("/customer")
    public List<Customers> findAll() {
        return customersRepository.findAll();
    }

    @ResponseStatus(HttpStatus.OK)
    @GetMapping("/customer/name/{customerName}")
    public List<Customers> findByCustomerByName(@PathVariable String customerName) {
        return customersRepository.findByCustomerNameIsContaining(customerName);
    }


    /**
     * Get Customer with specific ID.
     * @param id The CustomerId
     * @return If the customers is found, a customer and HTTP Status code.
     */
    @GetMapping("/customer/{id}")
    public ResponseEntity<Customers> getCustomerById(@PathVariable("id") String id) {
        Optional<Customers> customerData = customersRepository.findById(id);
        try {
            return customerData.map(customers -> new ResponseEntity<>(customers, HttpStatus.OK))
                    .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Get customer that contains an email.
     * @param email of the customer
     * @return Returns a customer if found
     */
    @GetMapping("/customer/byemail/{email}")
    public List<Customers> getCustomerByEmail(@PathVariable("email") String email) {
        return customersRepository.findByCustomerEmailIsContaining(email);
    }

    /**
     * Create a customer.
     * @param customer  Customer object with the customer details
     * @return Returns a HTTP Status code
     */
    @PostMapping("/customer")
    public ResponseEntity<Customers> createCustomer(@RequestBody Customers customer) {
        try {
            Customers newCustomer = customersRepository.save(new Customers(
                    customer.getCustomerId(),
                    customer.getCustomerName(),
                    customer.getCustomerEmail(),
                    customer.getCustomerOtherDetails()));
            return new ResponseEntity<>(newCustomer, HttpStatus.CREATED);

        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Update a specific Customer (ID).
     * @param id The id of the customer
     * @param customer A customer object
     * @return A Http Status code
     */
    @PutMapping("/customer/{id}")
    public ResponseEntity<Customers> updateCustomer(@PathVariable("id") String id, @RequestBody Customers customer) {
        Optional<Customers> customerData = customersRepository.findById(id);
        try {
            if (customerData.isPresent()) {
                Customers updCustomer = customerData.get();
                updCustomer.setCustomerName(customer.getCustomerName());
                updCustomer.setCustomerEmail(customer.getCustomerEmail());
                updCustomer.setCustomerOtherDetails(customer.getCustomerOtherDetails());
                return new ResponseEntity<>(customersRepository.save(updCustomer), HttpStatus.OK);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Delete a specific customer (ID).
     * @param customerId the Id of the customer to be deleted
     * @return A Http Status code
     */
    @DeleteMapping("/customer/{customerId}")
    public ResponseEntity<HttpStatus> deleteCustomer(@PathVariable("customerId") String customerId) {
        try {
            customersRepository.deleteById(customerId);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Method isn't implemented.
     * @param amount Loan amount
     * @return A Http Status
     */
    @PostMapping("/customer/applyLoan/{amount}")
    public ResponseEntity<HttpStatus> applyForLoan(@PathVariable ("amount") long amount) {
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
