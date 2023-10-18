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
