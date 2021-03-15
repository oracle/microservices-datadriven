/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.http;

import com.helidon.se.http.service.InventoryService;
import com.helidon.se.persistence.Database;

import io.helidon.config.Config;

public class InventoryApi extends WebApi {

    public InventoryApi(Database database, Config config) {
        super(config, r -> r.register("/inventory", new InventoryService(database)));
    }

}
