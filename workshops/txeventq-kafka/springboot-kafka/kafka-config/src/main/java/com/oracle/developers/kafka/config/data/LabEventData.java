package com.oracle.developers.kafka.config.data;

import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;

import java.io.Serializable;

public class LabEventData implements Serializable {
    private String id;
    private String message;

    public static final String LAB_EVT_SCHEMA =
            "{\"namespace\": \"com.oracle.developers\","+
                    "\"type\":\"record\"," +
                    "\"doc\":\"This event records the txeventq lab\"," +
                    "\"name\":\"LabEvent\"," +
                    "\"fields\":["+
                        "{\"name\":\"id\",\"type\":\"string\"},"+
                        "{\"name\":\"message\",\"type\":\"string\"}"+
            "]}";


    public LabEventData() {}

    public LabEventData(String id, String message) {
        this.id = id;
        this.message = message;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public GenericRecord getAvroRecord() {
        Schema.Parser parser = new Schema.Parser();
        Schema schema = parser.parse(LAB_EVT_SCHEMA);

        GenericRecord avroRecord = new GenericData.Record(schema);
        avroRecord.put("id", this.id);
        avroRecord.put("message", this.message);

        return avroRecord;
    }
}
