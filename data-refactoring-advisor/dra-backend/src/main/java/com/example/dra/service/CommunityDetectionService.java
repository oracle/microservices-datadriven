// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

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
