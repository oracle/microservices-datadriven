// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ticket;

import java.sql.Connection;
import java.util.List;
import java.util.Optional;

public interface TicketStore {
    void saveTicket(Connection conn, SupportTicket ticket);

    SupportTicket create(SupportTicket ticket);

    List<SupportTicket> getAllTickets();

    Optional<SupportTicket> findById(Long id);

    void deleteAll();
}
