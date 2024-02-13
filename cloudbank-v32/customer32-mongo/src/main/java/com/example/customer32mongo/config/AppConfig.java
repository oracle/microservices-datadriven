// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32mongo.config;

import com.mongodb.ConnectionString;
import com.mongodb.MongoClientSettings;
import com.mongodb.ServerApi;
import com.mongodb.ServerApiVersion;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.MongoDatabaseFactory;
import org.springframework.data.mongodb.core.SimpleMongoClientDatabaseFactory;

@Configuration
public class AppConfig {

    @Value("${spring.data.mongodb.uri}")
    private String uri;

    @Value("${spring.data.mongodb.database}")
    private String db;

    // for information on how mongo is configured in Spring Data Mongo, please see these references:
    // 
    // https://docs.spring.io/spring-data/mongodb/reference/mongodb/configuration.html
    // https://www.mongodb.com/docs/drivers/java/sync/current/fundamentals/connection/connect/#atlas-connection-example

    /**
     * Configure the Mongo Client.
     * 
     * In particular, use TLS and ignore host name validation.  This is equivalent to invoking mongosh
     * with the following arguments:
     * 
     * `mongosh --tls --tlsAllowInvalidCertificates 'mongodb://...'`
     * 
     * @return the MongoClient configured for Oracle.
     */
    @Bean
    public MongoClient mongoClient() {

        ServerApi serverApi = ServerApi.builder()
                .version(ServerApiVersion.V1)
                .build();

        MongoClientSettings settings = MongoClientSettings.builder()
                .applyConnectionString(new ConnectionString(uri))
                .serverApi(serverApi)
                .applyToSslSettings(builder -> {
                    builder.enabled(true);
                    builder.invalidHostNameAllowed(true);
                })
                .build();

        return MongoClients.create(settings);
    }

    @Bean
    public MongoDatabaseFactory mongoDatabaseFactory() {
        return new SimpleMongoClientDatabaseFactory(mongoClient(), db);
    }

}
