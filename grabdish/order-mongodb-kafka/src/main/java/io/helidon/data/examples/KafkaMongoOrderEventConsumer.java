package io.helidon.data.examples;


public class KafkaMongoOrderEventConsumer implements Runnable {

    @Override
    public void run() {
        System.out.println("Receive messages...");
//        try {
            dolistenForMessages();
//        } catch (JMSException e) {
//            e.printStackTrace();
//        }
    }

    public void dolistenForMessages() {
if (true) return;
        String messageText = "textfromkafkamessage";
        Inventory inventory = JsonUtils.read(messageText, Inventory.class);
        String orderid = inventory.getOrderid();
        String itemid = inventory.getItemid();
        String inventorylocation = inventory.getInventorylocation();
        System.out.println("Lookup orderid:" + orderid + "(itemid:" + itemid + ")");
        Order order = null; //get order json from kafka message
        boolean isSuccessfulInventoryCheck = !(inventorylocation == null || inventorylocation.equals("")
                || inventorylocation.equals("inventorydoesnotexist")
                || inventorylocation.equals("none"));
        if (isSuccessfulInventoryCheck) {
            order.setStatus("success inventory exists");
            order.setInventoryLocation(inventorylocation);
            order.setSuggestiveSale(inventory.getSuggestiveSale());
        } else {
            order.setStatus("failed inventory does not exist");
        }
    }
}
