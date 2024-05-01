package com.example.tollreader;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.context.ApplicationListener;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.Lifecycle;
import org.springframework.core.task.TaskExecutor;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.MessageCreator;
import org.springframework.stereotype.Component;

import com.example.tollreader.data.Customer;
import com.example.tollreader.data.DataBean;
import com.example.tollreader.data.Vehicle;

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

    @Autowired
    private ConfigurableApplicationContext context;

    @Autowired
    private JmsTemplate jmsTemplate;

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
        // private static final Integer minNumber = 10000;
        // private static final Integer maxNumber = 99999;

        public MessageSenderTask(int delay) {
            this.delay = delay;
        }

        // private static <T extends Enum<?>> T randomEnum(Class<T> clazz) {
        //     int x = random.nextInt(clazz.getEnumConstants().length);
        //     return clazz.getEnumConstants()[x];
        // }

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

            DataBean dataBean = (DataBean) context.getBean("dataBean");
            Vehicle v = dataBean.getVehicles().get(random.nextInt(dataBean.getVehicles().size()));
            Customer c = dataBean.getCustomer(v.getCustomerId());

            String licNumber = v.getLicensePlate();
            String tagId = v.getTagId();
            String accountNumber = c.getAccountNumber();
            String state = v.getState();
            String vehicleType = v.getVehicleType();

            JsonObject data = Json.createObjectBuilder()
                    .add("accountNumber", accountNumber) // This could be looked up in the DB from the tagId?
                    .add("licensePlate", state + "-" + licNumber) // This could be looked up in the DB from the tagId?
                    .add("vehicleType", vehicleType) // This could be looked up in the DB from the tagId?
                    .add("tagId", tagId)
                    .add("tollDate", dateTimeString)
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
                } catch (Exception ignore) {
                }
            }
        }
    }

}
