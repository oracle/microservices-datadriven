package com.example.dra.entity;

import lombok.Getter;
import lombok.Setter;

import java.util.List;
@Getter
@Setter
public class GraphData {
    List<Nodes> nodes;
    List<Edges> edges;
}
