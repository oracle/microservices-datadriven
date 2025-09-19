package com.oracle.demo.lab.events;

import com.oracle.demo.lab.ai.embedding.EmbeddingService;
import com.oracle.demo.lab.ai.vectorstore.TicketVectorStore;
import com.oracle.demo.lab.ticket.RelatedTicket;
import com.oracle.demo.lab.ticket.SupportTicket;
import com.oracle.demo.lab.ticket.TicketStore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.util.Set;

@Component
@Profile("ai")
public class GenAIEventProcessor implements TicketEventProcessor {
    private static final Logger log = LoggerFactory.getLogger(GenAIEventProcessor.class);

    private final TicketVectorStore ticketVectorStore;
    private final EmbeddingService embeddingService;
    private final TicketStore ticketStore;

    public GenAIEventProcessor(TicketVectorStore ticketVectorStore,
                               EmbeddingService embeddingService, TicketStore ticketStore) {
        this.ticketVectorStore = ticketVectorStore;
        this.embeddingService = embeddingService;
        this.ticketStore = ticketStore;
    }

    @Override
    public void processRecord(Connection conn, SupportTicket ticket) {
        log.info("Processing ticket {}", ticket);
        float[] vector = embeddingService.embed(ticket.getTitle() + "\n" + ticket.getDescription());
        ticket.setEmbedding(vector);
        Set<RelatedTicket> relatedTickets = ticketVectorStore.search(0.2, vector, ticket.getId(), conn);
        ticket.setRelatedTickets(relatedTickets);

        log.info("Found {} related tickets for ticket id {}", relatedTickets.size(), ticket.getId());
        ticketStore.saveTicket(conn, ticket);
    }
}
