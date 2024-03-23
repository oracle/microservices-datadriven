// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32.service;

import java.util.List;
import java.util.Optional;

import com.example.customer32.model.Customer;

public interface CustomerService {

    List<Customer> findAll();

    Optional<Customer> findByCustomerByName(String name);

    Optional<Customer> findCustomerById(String id);

    Optional<Customer> findCustomerByEmail(String email);

    int createCustomer(Customer customer);

    int updateCustomer(Customer customer, String id);

    int deleteCustomer(String id);

}
