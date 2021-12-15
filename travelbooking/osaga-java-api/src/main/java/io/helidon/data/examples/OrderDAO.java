/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import java.sql.Connection;
import java.util.Objects;
import oracle.soda.OracleCollection;
import oracle.soda.OracleDatabase;
import oracle.soda.OracleDocument;
import oracle.soda.OracleException;
import oracle.soda.rdbms.OracleRDBMSClient;

public class OrderDAO {
    private final String collectionName = "travelagencyscollection";

    public Order get(Connection conn, String id) throws OracleException {
        OracleDatabase soda = new OracleRDBMSClient().getDatabase(conn);
        OracleCollection col = soda.openCollection(collectionName);
        if(col == null) return null;
        OracleDocument doc = col.find().key(id).getOne();
        if (Objects.nonNull(doc)) {
            return JsonUtils.read(doc.getContentAsString(), Order.class);
        } else {
            return null;
        }
    }

    public Order create(Connection conn, Order travelagency) throws OracleException {
        OracleDatabase soda = new OracleRDBMSClient().getDatabase(conn);
        OracleCollection col = soda.openCollection(collectionName);
        if (col == null) {
            OracleDocument metaDoc = new OracleRDBMSClient().createMetadataBuilder().mediaTypeColumnName("CONTENT_TYPE").keyColumnAssignmentMethod("CLIENT").build();
            col = soda.admin().createCollection(collectionName, metaDoc);
        }
        OracleDocument doc = soda.createDocumentFromString(travelagency.getOrderid(), JsonUtils.writeValueAsString(travelagency));
        col.insert(doc);
        System.out.println("Created travelagency:" + travelagency);
        return travelagency;
    }

    public void update(Connection conn, Order travelagency) throws OracleException {
        OracleDatabase soda = new OracleRDBMSClient().getDatabase(conn);
        OracleCollection col = soda.openCollection(collectionName);
        OracleDocument doc = soda.createDocumentFromString(travelagency.getOrderid(), JsonUtils.writeValueAsString(travelagency));
        col.find().key(travelagency.getOrderid()).replaceOne(doc);
        System.out.println("Updated travelagency:" + travelagency);
    }

    public String drop(Connection conn) throws OracleException {
        OracleDatabase soda = new OracleRDBMSClient().getDatabase(conn);
        OracleCollection col = soda.openCollection(collectionName);
        if (col != null && col.admin() !=null) col.admin().drop();
        return collectionName + " dropped";
    }

    public int delete(Connection conn, String id) throws OracleException {
        OracleDatabase soda = new OracleRDBMSClient().getDatabase(conn);
        OracleCollection col = soda.openCollection(collectionName);
        return col.find().key(id).remove();
    }

}