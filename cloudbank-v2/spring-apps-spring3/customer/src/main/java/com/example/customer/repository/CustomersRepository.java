// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.customer.repository;

import com.example.customer.model.Customers;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CustomersRepository extends JpaRepository<Customers, String> {

    List<Customers> findByCustomerNameIsContaining(String customerName);
    List<Customers> findByCustomerEmailIsContaining(String customerEmail);

    // Optional<Customers> findByEmail(String email);
}
