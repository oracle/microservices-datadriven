/*
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.oracle.developers.txeventq.okafka.config.data;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "okafka-server-config")
public class OKafkaConfigData {
    // Database Configuration

    private String oracleInstanceName;  //name of the oracle database instance
    private String oracleServiceName;   //name of the service running on the instance
    private String oracleNetTns_admin;  //location of tnsnames.ora/ojdbc.properties file
    private String tnsAlias;            // "alias of connection string in tnsnames.ora. This connection is used for connecting to database instance";
    private String oracleUserName;
    private String oraclePassword;

    private String securityProtocol;
    private String bootstrapServers;

    public OKafkaConfigData() {}

    public OKafkaConfigData(String oracleInstanceName, String oracleServiceName, String oracleNetTns_admin, String tnsAlias, String oracleUserName, String oraclePassword, String securityProtocol, String bootstrapServers) {
        this.oracleInstanceName = oracleInstanceName;
        this.oracleServiceName = oracleServiceName;
        this.oracleNetTns_admin = oracleNetTns_admin;
        this.tnsAlias = tnsAlias;
        this.oracleUserName = oracleUserName;
        this.oraclePassword = oraclePassword;
        this.securityProtocol = securityProtocol;
        this.bootstrapServers = bootstrapServers;
    }

    public String getOracleInstanceName() {
        return oracleInstanceName;
    }

    public void setOracleInstanceName(String oracleInstanceName) {
        this.oracleInstanceName = oracleInstanceName;
    }

    public String getOracleServiceName() {
        return oracleServiceName;
    }

    public void setOracleServiceName(String oracleServiceName) {
        this.oracleServiceName = oracleServiceName;
    }

    public String getOracleNetTns_admin() {
        return oracleNetTns_admin;
    }

    public void setOracleNetTns_admin(String oracleNetTns_admin) {
        this.oracleNetTns_admin = oracleNetTns_admin;
    }

    public String getTnsAlias() {
        return tnsAlias;
    }

    public void setTnsAlias(String tnsAlias) {
        this.tnsAlias = tnsAlias;
    }

    public String getOracleUserName() {
        return oracleUserName;
    }

    public void setOracleUserName(String oracleUserName) {
        this.oracleUserName = oracleUserName;
    }

    public String getOraclePassword() {
        return oraclePassword;
    }

    public void setOraclePassword(String oraclePassword) {
        this.oraclePassword = oraclePassword;
    }

    public String getSecurityProtocol() {
        return securityProtocol;
    }

    public void setSecurityProtocol(String securityProtocol) {
        this.securityProtocol = securityProtocol;
    }

    public String getBootstrapServers() {
        return bootstrapServers;
    }

    public void setBootstrapServers(String bootstrapServers) {
        this.bootstrapServers = bootstrapServers;
    }

}
