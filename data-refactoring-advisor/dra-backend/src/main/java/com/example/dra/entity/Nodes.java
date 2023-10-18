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
