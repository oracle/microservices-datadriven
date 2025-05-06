package org.example.oracle_cqrs;

import jakarta.jms.ConnectionFactory;
import jakarta.jms.JMSException;
import oracle.jakarta.jms.AQjmsFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.jms.support.converter.MappingJackson2MessageConverter;
import org.springframework.jms.support.converter.MessageType;

import javax.sql.DataSource;

@SpringBootApplication
public class OracleCqrsApplication {

    public static void main(String[] args) {
        SpringApplication.run(OracleCqrsApplication.class, args);
    }

    @Bean
    public ConnectionFactory aqJmsConnectionFactory(DataSource ds) throws JMSException {
        return AQjmsFactory.getConnectionFactory(ds);
    }


    @Bean
    public MappingJackson2MessageConverter jacksonJmsMessageConverter() {
        MappingJackson2MessageConverter converter = new MappingJackson2MessageConverter();
        converter.setTargetType(MessageType.TEXT); // send as TEXTMessage (JSON)
        converter.setTypeIdPropertyName("_type");
        return converter;
    }

}
