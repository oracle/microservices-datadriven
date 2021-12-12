package com.aq;

import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.aq.basic.ClassicQueueBasic;
import com.aq.workflow.ClassicQueueWorkflow;

@RequestMapping("/oracleAQ")
@RestController
@CrossOrigin(maxAge = 3600)
public class OracleAQController {

	@Autowired(required = true)
	ClassicQueueBasic classicQueueBasic;

	@Autowired(required = true)
	ClassicQueueWorkflow classicQueueWorkflow;

	Logger logger = LoggerFactory.getLogger(OracleAQController.class);

	@GetMapping(value = "/lab1")
	public Map<String, Object> lab1() throws Exception {
		Map<String, Object> response = new HashMap();

		String status = classicQueueBasic.lab1();

		if (status.equalsIgnoreCase("Success")) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "Lab 1 successfully executed");
		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "Failed to execute Lab 1");
		}
		logger.info("AddUser response:{}", response);
		return response;
	}

	@GetMapping(value = "/lab2")
	public Map<String, Object> lab2() throws Exception {
		Map<String, Object> response = new HashMap();

		String status = classicQueueWorkflow.lab2();

		if (status.equalsIgnoreCase("Success")) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "Lab 2 successfully executed");
		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "Failed to execute Lab 2");
		}
		logger.info("AddUser response:{}", response);
		return response;
	}

}
