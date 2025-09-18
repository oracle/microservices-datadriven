package com.oracle.demo.lab.ticket;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.*;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.json.bind.annotation.JsonbProperty;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class SupportTicket {
    private static final Logger log = LoggerFactory.getLogger(SupportTicket.class);
    @JsonbProperty("_id")
    private Long id;
    private String title;
    private String description;
    private float[] embedding;

    private Set<RelatedTicket> relatedTickets = new HashSet<>();

    public SupportTicket() {
    }

    public SupportTicket(ResultSet rs) throws SQLException {
        this.id = rs.getLong("id");
        this.title = rs.getString("title");
        this.description = rs.getString("description");
        this.embedding = rs.getObject("embedding", float[].class);
        this.relatedTickets = new HashSet<>();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Set<RelatedTicket> getRelatedTickets() {
        return relatedTickets;
    }

    public void setRelatedTickets(Set<RelatedTicket> relatedTickets) {
        this.relatedTickets = relatedTickets;
    }

    public float[] getEmbedding() {
        return embedding;
    }

    public void setEmbedding(float[] embedding) {
        this.embedding = embedding;
    }

    public ProducerRecord<String, SupportTicket> toProducerRecord(String topic) {
        return new ProducerRecord<>(topic, this);
    }

    @Override
    public final boolean equals(Object o) {
        if (!(o instanceof SupportTicket that)) return false;

        return Objects.equals(getId(), that.getId());
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(getId());
    }

    @Override
    public String toString() {
        return "SupportTicket{" +
                "id=" + id +
                ", title='" + title + '\'' +
                ", description='" + description + '\'' +
                ", embedding=" + Arrays.toString(embedding) +
                ", relatedTickets=" + relatedTickets +
                '}';
    }
}
