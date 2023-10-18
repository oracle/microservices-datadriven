// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.controller;

import com.example.dra.ViewGraphResponse;
import com.example.dra.bean.DatabaseDetails;
import com.example.dra.dto.RefineCommunityDto;
import com.example.dra.dto.Tables18NodesDto;
import com.example.dra.service.CommunityDetectionService;
import com.example.dra.service.GraphConstructorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.apache.commons.lang3.time.StopWatch;

import com.example.dra.service.CreateSQLTuningSetService;

import java.util.Date;
import java.util.List;
import java.util.concurrent.TimeUnit;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class DRAController {
	
	@Autowired
	CreateSQLTuningSetService createSQLTuningSetService;

	@Autowired
	GraphConstructorService graphConstructorService;

	@Autowired
	CommunityDetectionService communityDetectionService;
	
	@GetMapping("/gettablename")
	public List<Tables18NodesDto> getTableName() {
		List<Tables18NodesDto> result = createSQLTuningSetService.getTableName();
		return result;
	}

	@PostMapping("/createsqltuningset")
	public String createSQLTuningSet(@RequestBody DatabaseDetails databaseDetails) {
		String result = createSQLTuningSetService.createSQLTuningSet(databaseDetails);
		return result;
	}

	@PostMapping("/dropsqltuningset")
	public String dropSQLTuningSet(@RequestBody DatabaseDetails databaseDetails) {
		String result = createSQLTuningSetService.dropSQLTuningSet(databaseDetails);
		return result;
	}

	@PostMapping("/loadsqltuningset")
	public String loadSQLTuningSet(@RequestBody DatabaseDetails databaseDetails) {
		String result = createSQLTuningSetService.loadSQLTuningSet(databaseDetails);
		return result;
	}

	@PostMapping("/collectsqltuningset")
	public String collectSQLTuningSet(@RequestBody DatabaseDetails databaseDetails) {

		StopWatch stopWatch = new StopWatch();
		stopWatch.start();

		System.out.println("Elapsed Time in minutes: "+ stopWatch.getTime());
		//String result = "In Collecting SQL Set";
		String result = createSQLTuningSetService.collectSQLTuningSet(databaseDetails);
		stopWatch.stop();
		//String str = null;
		//str.toString();
		result = "Time taken to Collect SQL Tuning Set : " + stopWatch.getTime(TimeUnit.SECONDS);
		System.out.println(result);
		return result;
	}

	@GetMapping("/getsqltuningsetlist")
	public List<String> getSQLTuningSetList() {
		DatabaseDetails databaseDetails = new DatabaseDetails();
		return createSQLTuningSetService.getSQLTuningSetList(databaseDetails);
	}

	@GetMapping("/viewgraph")
	public ViewGraphResponse viewGraph(@RequestParam("sqlSetName") String sqlSetName) {
		DatabaseDetails databaseDetails = new DatabaseDetails();
		databaseDetails.setSqlSetName(sqlSetName);
		return graphConstructorService.viewGraph(databaseDetails);
	}

	@GetMapping("/deletegraph")
	public boolean deleteGraph(@RequestParam("sqlSetName") String sqlSetName) {
		System.out.println("In Delete Graph Controller, For STS = " + sqlSetName);
		DatabaseDetails databaseDetails = new DatabaseDetails();
		databaseDetails.setSqlSetName(sqlSetName);
		return graphConstructorService.deleteGraph(databaseDetails);
	}

	@GetMapping("/communitydetection")
	public ViewGraphResponse communityDetection(@RequestParam("sqlSetName") String sqlSetName) {
		DatabaseDetails databaseDetails = new DatabaseDetails();
		databaseDetails.setSqlSetName(sqlSetName);
		return communityDetectionService.communityDetection(databaseDetails);
	}

	@GetMapping("/viewcommunity")
	public String viewCommunity(@RequestParam("sqlSetName") String sqlSetName) {
		DatabaseDetails databaseDetails = new DatabaseDetails();
		databaseDetails.setSqlSetName(sqlSetName);
		return communityDetectionService.viewCommunity(databaseDetails);
	}

	@PostMapping("/savecommunity")
	public String saveCommunity(@RequestBody DatabaseDetails databaseDetails) {
		System.out.println("In savecommunity Controller");
		System.out.println("STS : " + databaseDetails.getSqlSetName());
		System.out.println("Json : " + databaseDetails.getGraphData());
		String result = communityDetectionService.saveCommunity(databaseDetails);
		return result;
	}

	@GetMapping("/getRefineCommunityEdges")
	public List<RefineCommunityDto> getRefineCommunityEdges(@RequestParam("sqlSetName") String sqlSetName) {
		DatabaseDetails databaseDetails = new DatabaseDetails();
		databaseDetails.setSqlSetName(sqlSetName);
		return communityDetectionService.getRefineCommunityEdges(databaseDetails);
	}

	@PostMapping("/refinecommunity")
	public String refineCommunity(@RequestBody DatabaseDetails databaseDetails) {
		System.out.println("In refineCommunity Controller");
		System.out.println("STS : " + databaseDetails.getSqlSetName());
		// result = communityDetectionService.refineCommunityUsingColors(databaseDetails);
		String result = communityDetectionService.refineCommunityUsingAffinity(databaseDetails);
		System.out.println("Refine Community Completed for : " + databaseDetails.getSqlSetName());
		return result;
	}

}
