// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.service.impl;

import com.example.dra.bean.DatabaseDetails;
import com.example.dra.service.DRAUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;

@Component
public class DRAUtilsImpl implements DRAUtils {

    @Value("${spring.datasource.hostname}")
    private String hostname;
    @Value("${spring.datasource.port}")
    private String port;
    @Value("${spring.datasource.service.name}")
    private String serviceName;
    @Value("${spring.datasource.username}")
    private String username;
    @Value("${spring.datasource.password}")
    private String password;

    public DatabaseDetails setDatabaseDetails(DatabaseDetails databaseDetails) {
        System.out.println("App.props, hostname :: " + hostname);
        databaseDetails.setHostname(hostname);
        databaseDetails.setPort(Integer.parseInt(port));
        databaseDetails.setServiceName(serviceName);
        databaseDetails.setUsername(username);
        databaseDetails.setPassword(password);
        return databaseDetails;
    }

    public String formDbConnectionStr(DatabaseDetails databaseDetails) {
        String CLOUD_DB_URL_STR = "jdbc:oracle:thin:@(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)\n" +
                "(port="+databaseDetails.getPort()+")(host="+databaseDetails.getHostname()+"))\n" +
                "(connect_data=(service_name="+databaseDetails.getServiceName()+"))\n" +
                "(security=(ssl_server_dn_match=yes)))";
        return CLOUD_DB_URL_STR;
    }

}
