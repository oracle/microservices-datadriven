package com.aq;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.aq.basic.AQBasic;
import com.aq.workflow.AQWorkflow;

@RequestMapping("/oracleAQ")
@RestController
@CrossOrigin(maxAge = 3600)
public class OracleAQController {

	@Autowired(required = true)
	AQBasic classicQueueBasic;

	@Autowired(required = true)
	AQWorkflow classicQueueWorkflow;

	@GetMapping(value = "/aqEnqueueDequeue")
	public Map<String, Object> aqEnqueueDequeue() throws Exception {
		Map<String, Object> response = new HashMap();

		String status = classicQueueBasic.lab1();

		if (status.equalsIgnoreCase("Success")) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "AQ Enqueue and Dequeue execution SUCCESS ...!!!");
		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "AQ Enqueue and Dequeue execution FAILED ...!!!");
		}
		System.out.println("AQ Enqueue and Dequeue response:{}"+ response);
		return response;
	}

	@GetMapping(value = "/aqWorkflow")
	public Map<String, Object> aqWorkflow() throws Exception {
		Map<String, Object> response = new HashMap();

		String status = classicQueueWorkflow.lab2();

		if (status.equalsIgnoreCase("DELIVERED")) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "AQ workflow: Second-factor Authication execution SUCCESS ...!!!");
		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "AQ workflow: Second-factor Authication execution FAILED ...!!!");
		}
		System.out.println("AQ workflow: Second-factor Authication response:{}"+ response);
		return response;
	}

}
