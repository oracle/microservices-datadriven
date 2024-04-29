package com.example.tollreader;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationListener;
import org.springframework.context.Lifecycle;
import org.springframework.core.task.TaskExecutor;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.MessageCreator;
import org.springframework.stereotype.Component;

import jakarta.jms.JMSException;
import jakarta.jms.Message;
import jakarta.jms.Session;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j
public class MessageTaskExecutor implements Lifecycle {

    private TaskExecutor taskExecutor;
    private boolean running = false;
    private int delay = 1000;

	public MessageTaskExecutor(TaskExecutor taskExecutor) {
		this.taskExecutor = taskExecutor;
	}

    public void start() {
        running = true;
        log.info("started sending messages");
        taskExecutor.execute(new MessageSenderTask(delay));
    }

    public void stop() {
        running = false;
        log.info("stopped sending messages");
    }
    
    public boolean isRunning() {
        return running;
    }

    public void setDelay(int delay) {
        this.delay = delay;
    }

    private class MessageSenderTask implements Runnable {
        private int delay = 1000;
        private static final SecureRandom random = new SecureRandom();
        private static final Integer minNumber = 10000;
        private static final Integer maxNumber = 99999;

        public MessageSenderTask(int delay) {
            this.delay = delay;
        }

        @Autowired
        private JmsTemplate jmsTemplate;

        private static <T extends Enum<?>> T randomEnum(Class<T> clazz) {
            int x = random.nextInt(clazz.getEnumConstants().length);
            return clazz.getEnumConstants()[x];
        }

        // Why supresswarnings?  -- it's your ide making it required
        @SuppressWarnings("null")
        private void sendMessage(JsonObject tolldata) {
            jmsTemplate.send("TollGate", new MessageCreator() {
                @Override
                public Message createMessage(Session session) throws JMSException {
                    return session.createTextMessage(tolldata.toString());
                }
            });
        }

        public void sendMessage() throws Exception {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
            LocalDateTime now = LocalDateTime.now();
            String dateTimeString = now.format(formatter);

                int licNumber = random.nextInt(maxNumber - minNumber) + minNumber;
                int tagId = random.nextInt(maxNumber - minNumber) + minNumber;
                int accountNumber = random.nextInt(maxNumber - minNumber) + minNumber;
                String state = randomEnum(State.class).toString();
                String carType = randomEnum(CarType.class).toString();

                JsonObject data = Json.createObjectBuilder()
                    .add("accountnumber", accountNumber) // This could be looked up in the DB from the tagId?
                    .add("license-plate", state + "-" + Integer.toString(licNumber)) // This could be looked up in the DB from the tagId?
                    .add("cartype", carType) // This could be looked up in the DB from the tagId?
                    .add("tagid", tagId)
                    .add("timestamp", dateTimeString)
                    .build();

                log.info("Toll Data :" + data.toString());
                sendMessage(data);
            }
            

            public void run() {
                while (isRunning()) {
                try {
                    // wait first so we always wait even if sendMessage() fails
                    Thread.sleep(delay);
                    sendMessage();
                } catch (Exception ignore) {}
            }
        }  
    }

}
