// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.entity;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RefineNodes {
    String source;
    String destination;
    double affinity;

    @Override
    public String toString() {
        return "RefineNodes{" +
                "sourceName='" + source + '\'' +
                ", destinationName='" + destination + '\'' +
                ", affinity=" + affinity +
                '}';
    }
}
