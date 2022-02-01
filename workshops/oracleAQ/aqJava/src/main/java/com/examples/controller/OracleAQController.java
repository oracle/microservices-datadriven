package com.examples.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.examples.enqueueDequeueAQ.EnqueueDequeueAQ;
import com.examples.enqueueDequeueTEQ.EnqueueDequeueTEQ;
import com.examples.workflowAQ.WorkflowAQ;
import com.examples.workflowTEQ.WorkflowTEQ;

@RequestMapping("/oracleAQ")
@RestController
@CrossOrigin(maxAge = 3600)
public class OracleAQController {

	@Autowired(required = true)
	EnqueueDequeueAQ enqueueDequeueAQ;
	
	@Autowired(required = true)
	EnqueueDequeueTEQ enqueueDequeueTEQ;

	@Autowired(required = true)
	WorkflowAQ workflowAQ;
	
	@Autowired(required = true)
	WorkflowTEQ workflowTEQ;

	@GetMapping(value = "/enqueueDequeueAQ")
	public Map<String, Object> enqueueDequeueAQ() throws Exception {
		Map<String, Object> response = new HashMap();

		String status = enqueueDequeueAQ.pointToPointAQ();

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
	
	@GetMapping(value = "/enqueueDequeueTEQ")
	public Map<String, Object> enqueueDequeueTEQ() throws Exception {
		Map<String, Object> response = new HashMap();

		String status = enqueueDequeueTEQ.pubSubTEQ();

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

	@GetMapping(value = "/workflowAQ")
	public Map<String, Object> workflowAQ() throws Exception {
		Map<String, Object> response = new HashMap();

		String status = workflowAQ.pubSubWorkflowAQ();

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
	
	@GetMapping(value = "/workflowTEQ")
	public Map<String, Object> workflowTEQ() throws Exception {
		Map<String, Object> response = new HashMap();


		String status = workflowTEQ.pubSubWorkflowTEQ();

		if (status.equalsIgnoreCase("Success")) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "TEQ Enqueue and Dequeue execution SUCCESS ...!!!");
		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "TEQ Enqueue and Dequeue execution FAILED ...!!!");
		}
		System.out.println("AQ Enqueue and Dequeue response:{}"+ response);
		return response;
	}

}
