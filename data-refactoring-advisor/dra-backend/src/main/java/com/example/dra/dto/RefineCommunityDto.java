// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.dto;

import com.example.dra.entity.Nodes;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class RefineCommunityDto {
    String source;
    List<EdgeDto> destinations;
    List<Nodes> nodes;

    @Override
    public String toString() {
        return "RefineCommunityDto{" +
                "source='" + source + '\'' +
                ", destinations=" + destinations +
                '}';
    }
}
