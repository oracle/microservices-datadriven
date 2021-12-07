package io.micronaut.data.examples;

import io.micronaut.context.annotation.Factory;
import io.micronaut.jms.annotations.JMSConnectionFactory;
import oracle.jms.AQjmsFactory;

import javax.jms.ConnectionFactory;
import javax.jms.JMSException;
import javax.sql.DataSource;

//@Factory
public class AQConfig {

    private final DataSource dataSource;

    public AQConfig(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @JMSConnectionFactory("aqConnectionFactory")
    public ConnectionFactory connectionFactory() throws JMSException {
        return null; //AQjmsFactory.getConnectionFactory(dataSource);
    }
}
