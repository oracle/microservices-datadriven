package org.oracle.okafka.support;

import org.oracle.okafka.clients.producer.ProducerRecord;
import org.oracle.okafka.clients.producer.RecordMetadata;

public class SendResult<K, V> {
    private final ProducerRecord<K, V> producerRecord;
    private final RecordMetadata recordMetadata;

    public SendResult(ProducerRecord<K, V> producerRecord, RecordMetadata recordMetadata) {
        this.producerRecord = producerRecord;
        this.recordMetadata = recordMetadata;
    }

    public ProducerRecord<K, V> getProducerRecord() {
        return this.producerRecord;
    }

    public RecordMetadata getRecordMetadata() {
        return this.recordMetadata;
    }

    public String toString() {
        return "SendResult [producerRecord=" + this.producerRecord + ", recordMetadata=" + this.recordMetadata + "]";
    }
}
