// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ticket;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class RelatedTicketJsonTest {
    @Test
    void scoredReferenceKeepsTheExistingResponseFields() {
        var json = new ObjectMapper().valueToTree(new RelatedTicket(7L, 0.82));

        assertEquals(2, json.size());
        assertEquals(7L, json.get("relatedTicketId").asLong());
        assertEquals(0.82, json.get("score").asDouble());
    }
}
