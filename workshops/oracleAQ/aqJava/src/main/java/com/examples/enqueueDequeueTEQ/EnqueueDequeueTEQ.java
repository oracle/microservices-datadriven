package com.examples.enqueueDequeueTEQ;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import javax.jms.JMSException;

import javax.jms.TopicSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.examples.config.ConfigData;
import com.examples.config.ConstantName;
import com.examples.util.pubSubUtil;
import com.fasterxml.jackson.core.JsonProcessingException;


@Service
public class EnqueueDequeueTEQ {
	
	@Autowired(required=true)
	private pubSubUtil pubSubUtil;
	
	@Autowired(required=true)
	private ConfigData configData;

	@Autowired(required = true)
	private ConstantName constantName;

	public Map<Integer,String> pubSubTEQ() throws JsonProcessingException, ClassNotFoundException, SQLException, JMSException {
		Map<Integer,String> response = new HashMap();

		TopicSession session = configData.topicDataSourceConnection();
		response.put(1, "Topic Connection created.");

		pubSubUtil.pubSub(session, constantName.teq_pubSubSubscriber1, constantName.teq_pubSubQueue, "Sample text message");
		response.put(2, "Topic pubSub  executed.");

		return response;
	}

}
