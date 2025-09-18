package com.oracle.demo.lab.ticket;

import oracle.jdbc.OracleType;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Component
@Profile("!json")
public class SimpleSQLTicketStore implements TicketStore {
    private static final String UPDATE_TICKET_SQL = """
        UPDATE support_ticket
        SET embedding = ?
        WHERE id = ?
    """;

    private static final String INSERT_RELATION_SQL = """
        INSERT INTO related_ticket (ticket_id, related)
        VALUES (?, ?)
    """;

    private final JdbcClient jdbcClient;
    private final RowMapper<SupportTicket> rowMapper;

    public SimpleSQLTicketStore(JdbcClient jdbcClient, RowMapper<SupportTicket> rowMapper) {
        this.jdbcClient = jdbcClient;
        this.rowMapper = rowMapper;
    }


    @Override
    public SupportTicket create(SupportTicket ticket) {
        final String insert = """
        insert into support_ticket (title, description)
        values (?, ?)
    """;
        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcClient.sql(insert)
                .param(ticket.getTitle())
                .param(ticket.getDescription())
                .update(keyHolder, "id");

        return jdbcClient.sql("select * from support_ticket where id = ?")
                .param(keyHolder.getKey().longValue())
                .query(rowMapper)
                .single();
    }

    @Override
    public List<SupportTicket> getAllTickets() {
        return jdbcClient.sql("select * from support_ticket")
                .query(rowMapper).list();
    }

    @Override
    public Optional<SupportTicket> findById(Long id) {
        return jdbcClient.sql("select * from support_ticket where id = ?")
                .param(id)
                .query(rowMapper).optional();
    }

    @Override
    public void saveTicket(Connection conn, SupportTicket ticket) {
        if (ticket.getId() == null) {
            throw new IllegalArgumentException("Ticket ID must not be null for update.");
        }

        try (PreparedStatement ps = conn.prepareStatement(UPDATE_TICKET_SQL)) {
            ps.setObject(1, ticket.getEmbedding(), OracleType.VECTOR.getVendorTypeNumber()); // Customize this for actual vector handling
            ps.setLong(2, ticket.getId());

            int rows = ps.executeUpdate();
            if (rows == 0) {
                throw new SQLException("Updating ticket failed, no rows affected.");
            }

            insertRelatedTickets(conn, ticket);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void deleteAll() {
        jdbcClient.sql("truncate table related_ticket");
        jdbcClient.sql("truncate table support_ticket");
    }

    private void insertRelatedTickets(Connection conn, SupportTicket ticket) {
        Set<RelatedTicket> relatedTickets = ticket.getRelatedTickets();
        if (relatedTickets == null || relatedTickets.isEmpty()) return;

        try (PreparedStatement ps = conn.prepareStatement(INSERT_RELATION_SQL)) {
            for (RelatedTicket related : relatedTickets) {
                if (related.getRelatedTicketId() == null) {
                    throw new IllegalArgumentException("Non-existent related ticket");
                }
                ps.setLong(1, ticket.getId());
                ps.setLong(2, related.getRelatedTicketId());
                ps.addBatch();
            }
            ps.executeBatch();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}
