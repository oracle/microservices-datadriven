package org.example.oracle.cqrs;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.jms.support.converter.MappingJackson2MessageConverter;
import org.springframework.jms.support.converter.MessageType;


@SpringBootApplication
public class OracleCqrsApplication {

    public static void main(String[] args) {
        SpringApplication.run(OracleCqrsApplication.class, args);
    }


    @Bean
    public MappingJackson2MessageConverter jacksonJmsMessageConverter() {
        MappingJackson2MessageConverter converter = new MappingJackson2MessageConverter();
        converter.setTargetType(MessageType.TEXT); // send as TEXTMessage (JSON)
        converter.setTypeIdPropertyName("_type");
        return converter;
    }
}
