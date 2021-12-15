package io.helidon.data.examples;

/*
   DESCRIPTION
    This is the Saga Initiator class example, this class is responsible for initiating the saga using AQjmsSaga API and finalizing it upon successful completion of participant transactions.
   PRIVATE CLASSES    None
   NOTES:  These are code snippets only and this sample should be used for reference.
    */

import oracle.AQ.*;
import oracle.jms.*;
import javax.jms.*;
import java.lang.*;
import java.math.*;
import java.util.*;

public class TravelAgency {
    /* Initiate a saga and register message listener for the Travel Agency */
//    public static void main()
//            throws java.sql.SQLException, ClassNotFoundException, JMSException {
//        /* get the Topic Connection Factory */
//        TopicConnectionFactory tc_fact =  AQjmsFactory.getTopicConnectionFactory(url, prop);
//
//        /* create topic connection and session for the listener and the publisher */
//        TopicConnection t_conn = tc_fact.createTopicConnection();
//        TopicSession t_sess = t_conn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
//        TopicSession pub_sess = t_conn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
//
//        /* Get a handle to inbound topic and setup the subscriber */
//        TravelAgencyIn_topic =
//                ((AQjmsSession) t_sess).getSagaInTopic("JMSUSER", "TravelAgency");
//        t_subs = t_sess.createDurableSubscriber(TravelAgencyIn_topic, "TravelAgency");
//        /* setup the message listener for the Travel Agency */
//        TravelAgencyListener tlis = new TravelAgencyListener("TravelAgency", t_sess);
//        MessageListener myTravelListener = (MessageListener) tlis;
//        t_subs.setMessageListener(myTravelListener);
//
//        /* Get a handle to the outbound topic */
//        TravelAgencyOut_topic =
//                ((AQjmsSession) pub_sess).getSagaOutTopic("JMSUSER", "TravelAgency");
//        /* create a publisher */
//        TravelAgency_publisher = pub_sess.createPublisher(TravelAgencyOut_topic);
//
//        /* Initialize AQjmsSaga class and begin a saga */
//        SagaTravel = new AQjmsSaga("TravelAgency", pub_sess);
//        SagaTravel.begin();
///* SAGA$ database table entries at TravelAgencyPDB:
//Id	Level	Initiator	Coordinator	User#	Duration	Begin	End 	status
//1234	0	TravelAgency	TACoordinator	456	Null	07/23/2020	07/24/2020	0
//
//*/
//
//
//        /* prepare message for the Airline reservation */
//        Message_Airline.SetJMSSagaRecipient("Airline");
//        Message_Airline.SetText("{ "Reservation_Name": "Sample1", "Name": "John Doe", "Departure": "SFO", "Destination": "LAX", "Date": "10102020"}");
//
//        /* publish the message to Airline Reservation */
//        TravelAgency_publisher.publish(TravelAgencyOut_topic, Message_Airline);
//
//        /* commit the local transaction */
//        pub_sess.commit();
//    }
}
