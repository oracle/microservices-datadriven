package com.oracle.demo.lab.ticket;

import com.oracle.spring.json.jsonb.JSONB;
import com.oracle.spring.json.jsonb.JSONBRowMapper;
import oracle.jdbc.OracleTypes;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

import java.sql.*;
import java.util.List;
import java.util.Optional;

@Component
@Profile("json")
public class JSONTicketStore implements TicketStore {
    private static final String UPDATE_SQL = """
            update ticket_dv v set data = ?
            where v.data."_id" = ?
            """;
    private static final String BY_ID_SQL = """
            select * from ticket_dv v
            where v.data."_id" = ?
            """;

    private final JdbcClient jdbcClient;
    private final JSONB jsonb;
    private final JSONBRowMapper<SupportTicket> rowMapper;

    public JSONTicketStore(JdbcClient jdbcClient, JSONB jsonb) {
        this.jdbcClient = jdbcClient;
        this.jsonb = jsonb;
        this.rowMapper = new JSONBRowMapper<>(jsonb, SupportTicket.class);
    }

    @Override
    public void saveTicket(Connection conn, SupportTicket ticket) {
        byte[] oson = jsonb.toOSON(ticket);
        try (PreparedStatement ps = conn.prepareStatement(UPDATE_SQL)) {
            ps.setObject(1, oson, OracleTypes.JSON);
            ps.setLong(2, ticket.getId());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public List<SupportTicket> getAllTickets() {
        return jdbcClient.sql("select * from ticket_dv")
                .query(rowMapper)
                .list();
    }

    @Override
    public Optional<SupportTicket> findById(Long id) {
        return jdbcClient.sql(BY_ID_SQL)
                .param(id)
                .query(rowMapper)
                .optional();
    }

    @Override
    public SupportTicket create(SupportTicket ticket) {
        throw new UnsupportedOperationException("Not implemented.");
    }

    @Override
    public void deleteAll() {
        jdbcClient.sql("truncate table related_ticket");
        jdbcClient.sql("truncate table support_ticket");
    }
}
