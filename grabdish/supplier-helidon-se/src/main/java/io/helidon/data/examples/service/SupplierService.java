/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples.service;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

import io.helidon.config.Config;
import io.helidon.webserver.Routing.Rules;
import io.helidon.webserver.ServerRequest;
import io.helidon.webserver.ServerResponse;
import io.helidon.webserver.Service;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

public class SupplierService implements Service {

    private final PoolDataSource pool;
    static String regionId = System.getenv("OCI_REGION").trim();
    static String pwSecretOcid = System.getenv("VAULT_SECRET_OCID").trim();
    static String pwSecretFromK8s = System.getenv("dbpassword").trim();

    public SupplierService(Config config) throws SQLException {

        String url = config.get("url").asString().get();
        String user = config.get("user").asString().get();
        String password = config.get("password").asString().get();
        System.out.printf("Using url: %s%n", url);
        pool = PoolDataSourceFactory.getPoolDataSource();
        pool.setURL(url);
        String pw;
        if(!pwSecretOcid.trim().equals("")) {
            pw = OCISDKUtility.getSecreteFromVault(true, regionId, pwSecretOcid);
        } else {
            pw = pwSecretFromK8s;
        }
        pool.setUser("INVENTORYUSER");
        pool.setPassword(pw);
        pool.setInactiveConnectionTimeout(60);
        pool.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
    }

    @Override
    public void update(Rules rules) {
        rules
                .get("/addInventory", this::addInventory)
                .get("/removeInventory", this::removeInventory)
                .get("/getInventory", this::getInventoryCount);
    }


    private void addInventory(ServerRequest serverRequest, ServerResponse serverResponse) {
        String response;
        String itemid = serverRequest.queryParams().first("itemid").get();
        System.out.println("SupplierService.addInventory itemid:" + itemid);
        try {
            Connection conn = pool.getConnection();
            conn.createStatement().execute(
                    "UPDATE inventory SET inventorycount = inventorycount + 1 where inventoryid = '" + itemid + "'");
            response = getInventoryCount(itemid, conn);
        } catch (SQLException ex) {
            response = ex.getMessage();
        }
        serverResponse.send(response);
    }

    void removeInventory(ServerRequest serverRequest, ServerResponse serverResponse) {
        String response;
        String itemid = serverRequest.queryParams().first("itemid").get();
        System.out.println("SupplierService.removeInventory itemid:" + itemid);
        try (Connection conn = pool.getConnection()) {
            conn.createStatement().execute(
                    "UPDATE inventory SET inventorycount = inventorycount - 1 where inventoryid = '" + itemid + "'");
            response = getInventoryCount(itemid, conn);
        } catch (SQLException ex) {
            response = ex.getMessage();
        }
        serverResponse.send(response);
    }

    void getInventoryCount(ServerRequest serverRequest, ServerResponse serverResponse) {
        String response;
        String itemid = serverRequest.queryParams().first("itemid").get();
        System.out.println("SupplierService.getInventoryCount itemid:" + itemid);
        try (Connection conn = pool.getConnection()) {
            response = getInventoryCount(itemid, conn);
        } catch (SQLException ex) {
            response = ex.getMessage();
        }
        serverResponse.send(response);
    }

    private String getInventoryCount(String itemid, Connection conn) throws SQLException {
        ResultSet resultSet = conn.createStatement().executeQuery(
                "select inventorycount from inventory  where inventoryid = '" + itemid + "'");
        int inventorycount;
        if (resultSet.next()) {
            inventorycount = resultSet.getInt("inventorycount");
            System.out.println("SupplierService.getInventoryCount inventorycount:" + inventorycount);
        } else inventorycount = 0;
        conn.close();
        return "inventorycount for " + itemid + " is now " + inventorycount;
    }

}