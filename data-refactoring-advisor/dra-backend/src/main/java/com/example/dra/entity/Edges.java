// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
//@Entity(name="EDGES")
public class Edges {

    /*@Id
    @Column(name = "TABLE_ID")
    private Long id;*/

    @Column(name="TABLE1")
    private String source;

    @Column(name="TABLE2")
    private String target;

    @Column(name="TOTAL_AFFINITY")
    private double weight;

}
