// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32mongo.service;

import java.util.List;
import java.util.Optional;

import com.example.customer32mongo.model.Customer;
import com.example.customer32mongo.repository.CustomerRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CustomerService {

    @Autowired
    private CustomerRepository repository;

    public List<Customer> findAll() {
        return repository.findAll();
    }

    public Optional<Customer> findByCustomerName(String name) {
        return repository.findByName(name);
    }

    public Optional<Customer> findByCustomerEmail(String email) {
        return repository.findByEmail(email);
    }

    public Optional<Customer> findByCustomerId(String id) {
        return repository.findById(id);
    }

    public Customer createCustomer(Customer customer) {
        return repository.save(customer);
    }

    /**
     * Update customer.
     * 
     * @param customer The customer document containing the udpates/deltas.
     * @param id The ID of the customer to update.
     * @return The udpated customer docuement.
     */
    public Customer updateCustomer(Customer customer, String id) {
        // if a document exists with the specified id, update it
        var existingDoc = repository.findById(id);
        if (existingDoc.isPresent()) {
            customer.id = existingDoc.get().id;
        }
        // if not, just create a new one
        return repository.save(customer);
    }

    public void deleteCustomer(String id) {
        repository.deleteById(id);
    }

}
