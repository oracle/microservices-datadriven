// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package com.example.customer;

public record CustomerRegistrationRequest(String firstName,
    String lastName,
    String email) {
}
