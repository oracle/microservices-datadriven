package com.example.tollreader;

import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.jms.ConnectionFactory;
import java.time.format.DateTimeFormatter;
import java.time.LocalDateTime;
import java.security.SecureRandom;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.jms.annotation.EnableJms;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.support.converter.MappingJackson2MessageConverter;
import org.springframework.jms.support.converter.MessageConverter;
import org.springframework.jms.support.converter.MessageType;

// dbms_aqadm.create_transactional_event_queue (queue_name => 'TollGate', multiple_consumers => true);
// dbms_aqadm.set_queue_parameter('TollGate', 'KEY_BASED_ENQUEUE', 2);
// dbms_aqadm.set_queue_parameter('TollGate', 'SHARD_NUM', 5);
// dbms_aqadm.start_queue('TollGate');
// end;
// /

@EnableJms
@SpringBootApplication
public class TollreaderApplication implements CommandLineRunner {

	private static final SecureRandom random = new SecureRandom();
	private static final Integer minNumber = 10000;
	private static final Integer maxNumber = 99999;

	@Autowired
    private JmsTemplate jmsTemplate;
	
	private static <T extends Enum<?>> T randomEnum(Class<T> clazz) {
		int x = random.nextInt(clazz.getEnumConstants().length);
		return clazz.getEnumConstants()[x];
	}

	private void sendMessage(JsonObject tolldata) {
        jmsTemplate.convertAndSend("TollGate", tolldata);
    }

	// Can I move this to a different class? service, component?
	// @Bean
    // public MessageConverter jacksonJmsMessageConverter() {
    //     MappingJackson2MessageConverter converter = new MappingJackson2MessageConverter();
    //     converter.setTargetType(MessageType.TEXT);
    //     converter.setTypeIdPropertyName("_type");
    //     return converter;
    // }

	// // Can I move this to a different class? service, component?
    // @Bean
    // public JmsTemplate jmsTemplate(ConnectionFactory connectionFactory) {
    //     JmsTemplate jmsTemplate = new JmsTemplate();
    //     jmsTemplate.setConnectionFactory(connectionFactory);
    //     jmsTemplate.setMessageConverter(jacksonJmsMessageConverter());
    //     return jmsTemplate;
    // }

	@Override
	public void run(String... args) throws Exception {
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
		LocalDateTime now = LocalDateTime.now();
		String dateTimeString = now.format(formatter);

		for (int i = 0; i < 10; i++) {
			Thread.sleep(1000);

			Integer licNumber = random.nextInt(maxNumber - minNumber) + minNumber;
			Integer tagId = random.nextInt(maxNumber - minNumber) + minNumber;
			Integer accountNumber = random.nextInt(maxNumber - minNumber) + minNumber;
			String state = randomEnum(State.class).toString();
			String carType = randomEnum(CarType.class).toString();

			JsonObject data = Json.createObjectBuilder()
			.add("accountnumber", accountNumber) // This could be looked up in the DB from the tagId?
			.add("license-plate", state + "-" + licNumber.toString()) // This could be looked up in the DB from the tagId?
			.add("cartype", carType) // This could be looked up in the DB from the tagId?
			.add("tagid", tagId)
			.add("timestamp", dateTimeString)
			.build();

			System.out.println(data);
			sendMessage(data);

		}
	}

	public static void main(String[] args) {
		SpringApplication.run(TollreaderApplication.class, args);
	}

}
