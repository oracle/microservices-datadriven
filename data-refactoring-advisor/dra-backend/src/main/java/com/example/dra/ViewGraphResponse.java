package com.example.dra;

import com.example.dra.entity.Edges;
import com.example.dra.entity.Nodes;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Setter
@Getter
public class ViewGraphResponse {
    List<Nodes> nodes;
    List<Edges> edges;
}
