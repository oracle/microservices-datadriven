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
