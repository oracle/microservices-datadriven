package com.example.dra.service;

import com.example.dra.ViewGraphResponse;
import com.example.dra.bean.DatabaseDetails;
import com.example.dra.dto.RefineCommunityDto;

import java.util.List;

public interface CommunityDetectionService {

    public ViewGraphResponse communityDetection(DatabaseDetails databaseDetails);

    public String viewCommunity(DatabaseDetails databaseDetails);

    String saveCommunity(DatabaseDetails databaseDetails);

    List<RefineCommunityDto> getRefineCommunityEdges(DatabaseDetails databaseDetails);

    String refineCommunityUsingColors(DatabaseDetails databaseDetails);

    String refineCommunityUsingAffinity(DatabaseDetails databaseDetails);
}
