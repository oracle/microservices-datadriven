/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.txeventq.okafka.config.data;

import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;

import java.io.Serializable;

public class LabResponseData implements Serializable {
    private String id;
    private String statusMessage;


    public LabResponseData() {}

    public LabResponseData(String id, String statusMessage) {
        this.id = id;
        this.statusMessage = statusMessage;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getStatusMessage() {
        return statusMessage;
    }

    public void setStatusMessage(String statusMessage) {
        this.statusMessage = statusMessage;
    }

    public String toString() {
        return "{\"id\":"+ id + ","
                + "{\"status\":"+ statusMessage + "}";
    }

    /*
    public GenericRecord getAvroRecord() {
        Schema.Parser parser = new Schema.Parser();
        Schema schema = parser.parse(LAB_RESPONSE_SCHEMA);

        GenericRecord avroRecord = new GenericData.Record(schema);
        avroRecord.put("id", this.id);
        avroRecord.put("status", this.statusMessage);

        return avroRecord;
    }
     */
}