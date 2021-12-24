package com.springboot.travelparticipant;

import AQSaga.AQjmsSagaMessageListener;

public class TravelParticipantSagaMessageListener extends AQjmsSagaMessageListener{

    //in-memory
    int tickets = 2;

    @Override
    public String request(String sagaId, String payload) {
        System.out.println("Tickets remaining : " + --tickets);
        String response = "";
        if(tickets >= 0)
            return "[{\"result\":\"success\"}]";
        else
            return "[{\"result\":\"failure\"}]";
    }

    @Override
    public void response(String sagaId, String payload) {
        System.err.println(payload);
        System.out.println("Got resp!");
    }

    @Override
    public void beforeCommit(String sagaId) {
        System.out.println("bc Called");
    }

    @Override
    public void afterCommit(String sagaId) {
        System.out.println("ac Called");
    }

    @Override
    public void beforeRollback(String sagaId) {
        System.out.println("before rb");
        tickets++;
        System.out.println("Total Tickets : " + tickets);
    }

    @Override
    public void afterRollback(String sagaId) {
        System.out.println("after rb");
    }

}
