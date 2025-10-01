package com.oracle.demo.lab.ai.vectorstore;

import com.oracle.demo.lab.ticket.RelatedTicket;
import com.oracle.demo.lab.ticket.SupportTicket;
import com.oracle.spring.json.jsonb.JSONB;
import oracle.jdbc.OracleType;
import oracle.jdbc.OracleTypes;
import oracle.sql.VECTOR;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.sql.*;
import java.util.*;

/**
 * This sample class provides a vector abstraction for Oracle Database 23ai.
 * The sample class includes capabilities to create a table for embeddings, add embeddings, and execute similarity searches
 * against embeddings stored in the database.
 *
 * @author  Anders Swanson
 */
@Component
@Profile("ai")
public class TicketVectorStore {
    /**
     * A batch size of 50 to 100 records is recommending for bulk inserts.
     */
    private static final int BATCH_SIZE = 50;

    private final VectorDataAdapter dataAdapter;
    private final JSONB jsonb;

    public TicketVectorStore(VectorDataAdapter dataAdapter, JSONB jsonb) {
        this.dataAdapter = dataAdapter;
        this.jsonb = jsonb;
    }

    /**
     * Adds a list of Embeddings to the vector store, in batches.
     * @param tickets To add.
     * @param connection Database connection used for upsert.
     */
    public void addAll(ConsumerRecords<String, SupportTicket> tickets, Connection connection) {
        final String sql = """
                insert into ticket_dv (data) values(?)
                """;
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            int i = 0;
            for (ConsumerRecord<String, SupportTicket> record : tickets) {
                SupportTicket ticket = record.value();
                byte[] oson = jsonb.toOSON(ticket);

                stmt.setObject(1, oson, OracleTypes.JSON);
                stmt.addBatch();

                // If BATCH_SIZE records have been added to the statement, execute the batch.
                if (i % BATCH_SIZE == BATCH_SIZE - 1) {
                    stmt.executeBatch();
                }
                i++;
            }
            // If there are any remaining batches, execute them.
            if (tickets.count() % BATCH_SIZE != 0) {
                stmt.executeBatch();
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

public Set<RelatedTicket> search(double minScore, float[] vector, Long ticketId, Connection connection) {
        // This query is designed to:
        // 1. Calculate a similarity score for each row based on the cosine distance between the embedding column
        // and a given vector using the "vector_distance" function.
        // 2. Order the rows by this similarity score in descending order.
        // 3. Filter out rows with a similarity score below a specified threshold.
        // 4. Return only the top rows that meet the criteria.
        // 5. Group by article ID, so multiple chunks from the same article do not duplicate results.
        final String searchQuery = """
                with scored_tickets as (
                    select
                        id,
                        embedding,
                        (1 - vector_distance(embedding, ?, cosine)) as score
                    from support_ticket
                    where id != ?
                )
                select *
                from scored_tickets
                where score >= ?
                order by score desc
                fetch first 5 rows only""";

        Set<RelatedTicket> matches = new HashSet<>();
        try (PreparedStatement stmt = connection.prepareStatement(searchQuery)) {
            // When using the VECTOR data type with prepared statements, always use setObject with the OracleType.VECTOR targetSqlType.
            VECTOR v = VECTOR.ofFloat32Values(vector);
            stmt.setObject(1, v, OracleType.VECTOR.getVendorTypeNumber());
            stmt.setLong(2, ticketId);
            stmt.setObject(3, minScore, OracleType.NUMBER.getVendorTypeNumber());
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    RelatedTicket related = new RelatedTicket();
                    related.setRelatedTicketId(rs.getLong("id"));
                    matches.add(related);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        return matches;
    }
}
