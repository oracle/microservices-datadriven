package org.oracle.okafka.examples.model;

public class DataRecord {
    Long count;

    public DataRecord() {
    }

    public DataRecord(Long count) {
        this.count = count;
    }

    public Long getCount() {
        return count;
    }

    public String toString() {
        return "{\"count\":"+ count + "}";
    }
}
