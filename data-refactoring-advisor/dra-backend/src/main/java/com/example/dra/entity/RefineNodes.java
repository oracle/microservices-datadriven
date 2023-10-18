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
