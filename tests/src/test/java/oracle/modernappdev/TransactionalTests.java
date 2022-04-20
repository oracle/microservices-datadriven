/*
 ** Copyright (c) 2022 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package oracle.modernappdev;

import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.ContentType;
import org.apache.http.entity.StringEntity;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;



class TransactionalTests extends TestBase {

    //crash command names
    static final String crashAfterInsert = "crashAfterInsert"; //on order
    static final String crashAfterOrderMessageReceived = "crashAfterOrderMessageReceived"; //on inventory
    static final String crashAfterOrderMessageProcessed = "crashAfterOrderMessageProcessed"; //on inventory
    static final String crashAfterInventoryMessageReceived = "crashAfterInventoryMessageReceived"; //on order


    static {
        System.out.println("TransactionalTests frontendAddress:" + frontendAddress);
    }


     HttpResponse setCrashType(String crashType) throws Exception {
        System.out.println("TransactionalTests.setCrashType crashType:" + crashType);
        HttpPost request = new HttpPost( frontendAddress + command);
        Command command = new Command();
        command.commandName = crashType;
        if (crashType.equals(crashAfterInsert) || crashType.equals(crashAfterInventoryMessageReceived)) {
            command.serviceName = order;
        } else if (crashType.equals(crashAfterOrderMessageReceived) || crashType.equals(crashAfterOrderMessageProcessed)) {
            command.serviceName = inventory;
        } else throw new Exception("setCrashType unknown crashType:" + crashType);
        ObjectWriter ow = new ObjectMapper().writer().withDefaultPrettyPrinter();
        String jsonString = ow.writeValueAsString(command);
        StringEntity requestEntity = new StringEntity( jsonString, ContentType.APPLICATION_JSON);
        request.setEntity(requestEntity);
        HttpResponse httpResponse = getHttpClient().execute( request );
        System.out.println("TransactionalTests.crashType httpResponse.getEntity():" + httpResponse.getEntity().getContent());
        return httpResponse;
    }

}
