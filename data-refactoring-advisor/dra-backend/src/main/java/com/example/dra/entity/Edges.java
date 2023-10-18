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
