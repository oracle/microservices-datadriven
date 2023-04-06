package com.examples.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.examples.enqueueDequeueAQ.EnqueueDequeueAQ;
import com.examples.enqueueDequeueTxEventQ.EnqueueDequeueTxEventQ;
import com.examples.workflowAQ.WorkflowAQ;
import com.examples.workflowTxEventQ.WorkflowTxEventQ;

@RequestMapping("/oracleAQ")
@RestController
@CrossOrigin(maxAge = 3600)
public class OracleAQController {

	@Autowired(required = true)
	EnqueueDequeueAQ enqueueDequeueAQ;

	@Autowired(required = true)
	EnqueueDequeueTxEventQ enqueueDequeueTEQ;

	@Autowired(required = true)
	WorkflowAQ workflowAQ;

	@Autowired(required = true)
	WorkflowTxEventQ workflowTxEventQ;

	@GetMapping(value = "/pointToPointAQ")
	public Map<String, Object> pointToPointAQ() throws Exception {
		Map<String, Object> response = new HashMap();
		Map<Integer, String> responseBody= enqueueDequeueAQ.pointToPointAQ();
		
		if (responseBody != null) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "AQ PointToPoint execution SUCCESS ...!!!");
			response.put("ResponseBody", responseBody);

		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "AQ PointToPoint execution FAILED ...!!!");
		}
		System.out.println("AQ PointToPoint response: " + response);
		return response;
	}

	@GetMapping(value = "/pubSubAQ")
	public Map<String, Object> pubSubAQ() throws Exception {
		Map<String, Object> response = new HashMap();
		Map<Integer, String> responseBody= enqueueDequeueAQ.pubSubAQ();
				
		if (responseBody != null) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "AQ PubSub execution SUCCESS ...!!!");
			response.put("ResponseBody", responseBody);

		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "AQ PubSub execution FAILED ...!!!");
		}
		System.out.println("AQ PubSub response:" + response);
		return response;
	}

	@GetMapping(value = "/pubSubTEQ")
	public Map<String, Object> pubSubTEQ() throws Exception {
		Map<String, Object> response = new HashMap();
		Map<Integer, String> responseBody= enqueueDequeueTEQ.pubSubTEQ();

		if (responseBody != null) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "TEQ PubSub execution SUCCESS ...!!!");
			response.put("ResponseBody", responseBody);

		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "TEQ PubSub execution FAILED ...!!!");
		}
		System.out.println("TEQ PubSub response:" + response);
		return response;
	}

	@GetMapping(value = "/workflowAQ")
	public Map<String, Object> workflowAQ() throws Exception {
		Map<String, Object> response = new HashMap();
		Map<Integer, String> responseBody= workflowAQ.pubSubWorkflowAQ();
				
		if (responseBody != null) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "AQ workflow: Second-factor Authication execution SUCCESS ...!!!");
			response.put("ResponseBody", responseBody);

		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "AQ workflow: Second-factor Authication execution FAILED ...!!!");
		}
		System.out.println("AQ workflow: Second-factor Authication response:" + response);
		return response;
	}

	@GetMapping(value = "/workflowTEQ")
	public Map<String, Object> workflowTEQ() throws Exception {
		Map<String, Object> response = new HashMap();
		Map<Integer, String> responseBody= workflowTxEventQ.pubSubWorkflowTxEventQ();
				
		if (responseBody != null) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "TEQ Enqueue and Dequeue execution SUCCESS ...!!!");
			response.put("ResponseBody", responseBody);

		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "TEQ Enqueue and Dequeue execution FAILED ...!!!");
		}
		System.out.println("AQ Enqueue and Dequeue response:" + response);
		return response;
	}

}
