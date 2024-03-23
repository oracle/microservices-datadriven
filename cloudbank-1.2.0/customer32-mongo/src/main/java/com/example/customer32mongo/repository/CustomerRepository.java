// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32mongo.repository;

import java.util.Optional;

import com.example.customer32mongo.model.Customer;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.lang.NonNull;

public interface CustomerRepository extends MongoRepository<Customer, String> {
    public Optional<Customer> findByName(String name);

    public Optional<Customer> findByEmail(String email);
    
    public @NonNull Optional<Customer> findById(@NonNull String id);
}
