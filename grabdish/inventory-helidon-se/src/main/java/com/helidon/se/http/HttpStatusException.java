/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.http;

import lombok.Getter;

@Getter
public class HttpStatusException extends Exception {

    private final int status;

    public HttpStatusException(int status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatusException(int status, String message, Throwable cause) {
        super(message, cause);
        this.status = status;
    }
}
