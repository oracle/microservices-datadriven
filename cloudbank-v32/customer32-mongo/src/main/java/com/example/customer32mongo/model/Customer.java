// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32mongo.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("customers")
public class Customer {
    
    @Id
    public String id;

    public String name;
    public String email;

    public Customer() {
    }

    public Customer(String name, String email) {
        this.name = name;
        this.email = email;
    }

}
