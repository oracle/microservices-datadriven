// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.entity;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class Nodes {

    private String name;
    private String color;
    private int communityNumber;

    @Override
    public String toString() {
        return "Nodes{" +
                "name='" + name + '\'' +
                ", color='" + color + '\'' +
                '}';
    }
}
