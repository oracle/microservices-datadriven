package com.examples.config;

import org.springframework.stereotype.Component;

@Component
public class ConstantName {
	

	//AQ- Point to Point 
	public String aq_createTable = "JAVA_QUEUE_TABLE";
	public String aq_createQueue = "JAVA_QUEUE";
	
	public String aq_enqueueDequeueTable= "JAVA_ENQUEUE_DEQUEUE_QUEUE_TABLE";
	public String aq_enqueueDequeueQueue= "JAVA_ENQUEUE_DEQUEUE_QUEUE";
	
	public String aq_multiConsumerTable = "JAVA_MULTICONSUMER_QUEUE_TABLE";
	public String aq_multiConsumerQueue = "JAVA_MULTICONSUMER_QUEUE";
	
	//AQ- PUBSUB 
	public String aq_pubSubTable        = "JAVA_AQ_PUBSUB_QUEUE_TABLE";
	public String aq_pubSubQueue        = "JAVA_AQ_PUBSUB_QUEUE";
	public String aq_pubSubSubscriber1  = "JAVA_AQ_PUBSUB_SUBSCRIBER1";
	
	//TEQ- PUBSUB
	public String teq_pubSubQueue       = "JAVA_TEQ_PUBSUB_QUEUE";
	public String teq_pubSubSubscriber1 = "JAVA_TEQ_PUBSUB_SUBSCRIBER1";
	
	//AQ- WORKFLOW
	public String aq_userQueueTable                 = "JAVA_AQ_USER_QUEUE_TABLE";
	public String aq_userQueueName 				    = "JAVA_AQ_USER_QUEUE";
	public String aq_userApplicationSubscriber      = "JAVA_AQ_USER_APPLICATION_SUBS";
	public String aq_userDelivererSubscriber        = "JAVA_AQ_USER_DELIVERER_SUBS";

	public String aq_delivererQueueTable            = "JAVA_AQ_DELIVERER_QUEUE_TABLE";
	public String aq_delivererQueueName             = "JAVA_AQ_DELIVERER_QUEUE";
	public String aq_delivererApplicationSubscriber = "JAVA_AQ_DELIVERER_APPLICATION_SUBS";
	public String aq_delivererUserSubscriber        = "JAVA_AQ_DELIVERER_USER_SUBS";

	public String aq_applicationQueueTable          = "JAVA_AQ_APPLICATION_QUEUE_TABLE";
	public String aq_applicationQueueName           = "JAVA_AQ_APPLICATION_QUEUE";
	public String aq_applicationUserSubscriber      = "JAVA_AQ_APPLICATION_USER_SUBS";
	public String aq_applicationDelivererSubscriber = "JAVA_AQ_APPLICATION_DELIVERER_SUBS";
	
	//TEQ- WORKFLOW
	public String teq_userQueueName 				= "JAVA_TEQ_USER_QUEUE";
	public String teq_userApplicationSubscriber     = "JAVA_TEQ_USER_APPLICATION_SUBS";
	public String teq_userDelivererSubscriber       = "JAVA_TEQ_USER_DELIVERER_SUBS";

	public String teq_delivererQueueName            = "JAVA_TEQ_DELIVERER_QUEUE";
	public String teq_delivererApplicationSubscriber= "JAVA_TEQ_DELIVERER_APPLICATION_SUBS";
	public String teq_delivererUserSubscriber       = "JAVA_TEQ_DELIVERER_USER_SUBS";

	public String teq_applicationQueueName          = "JAVA_TEQ_APPLICATION_QUEUE";
	public String teq_applicationUserSubscriber     = "JAVA_TEQ_APPLICATION_USER_SUBS";
	public String teq_applicationDelivererSubscriber= "JAVA_TEQ_APPLICATION_DELIVERER_SUBS";


}
