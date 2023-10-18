// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

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
