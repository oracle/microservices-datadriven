package io.helidon.data.examples;

/* DESCRIPTION
 This is the Travel Agency listener example; this class implements the
 message listener for the travel agency.  It receives messages from   participant microservices and maintains state of the saga in the database.  Once all messages for a saga are received a commit/rollback is executed
PRIVATE CLASSES: None
NOTES:  These are code snippets only and this sample should be used for reference.
*/

import oracle.AQ.*;
import oracle.jms.*;
import javax.jms.*;
import java.lang.*;
import java.math.*;
import java.util.*;

public class TravelAgencyListener implements MessageListener
{
    Session             mysess;
    String              myname;
    public int          msgCount;
    public boolean      useMsgVector;
    public Vector       msgVector;
    TravelAgencyListener(String name, Session sess)
    {
        myname = name;
        mysess = sess;
    }
//
    public void onMessage(javax.jms.Message m)
    {
//        TextMessage      SagaM = (TextMessage ) m;
//        AQMessageProperty    m_property = null;
//        AQjmsSaga    SagaTravel;
//
//        /* if a valid saga message */
//        if (SagaM.getJMSSagaId())
//        {
//            SagaTravel = new AQjmsSaga("TravelAgency", mysess);
//            SagaTravel.setSagaid(SagaM.getJMSSagaId());
//
//	   /* Record saga branch txn status in local tables to maintain saga
//          state and commit local txn*/
//
//	/* Check if all participant responses are received and Saga is ready to
//         commit i.e. ResSuccessful is TRUE */
//            if all_messages_received
//            {
//                if ResSuccessful
//                SagaTravel.commit();
//	   else
//                SagaTravel.rollback();
//            }
//
//        }
//
//        mysess.commit();
//
    }
}

