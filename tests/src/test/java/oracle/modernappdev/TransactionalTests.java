/*
 ** Copyright (c) 2022 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package oracle.modernappdev;

import com.fasterxml.jackson.databind.DeserializationFeature;
import org.apache.http.HttpResponse;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.CredentialsProvider;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.config.Registry;
import org.apache.http.config.RegistryBuilder;
import org.apache.http.conn.socket.ConnectionSocketFactory;
import org.apache.http.conn.socket.PlainConnectionSocketFactory;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.conn.ssl.TrustSelfSignedStrategy;
import org.apache.http.entity.ContentType;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.impl.conn.PoolingHttpClientConnectionManager;
import org.apache.http.ssl.SSLContextBuilder;
import org.apache.http.util.EntityUtils;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;

import java.io.IOException;
import java.security.KeyManagementException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;


class TransactionalTests {

    //standard surefire, httpclient, junit, hamcrest used by all the java platforms (spring boot, quarkus, mn, helidon, etc.)
    //only requires the FRONTEND_URL (eg "https://129.80.106.37/" which can be obtained from
    // export FRONTEND_URL=$(kubectl get services --namespace msdataworkshop ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
    // export TEST_UI_PASSWORD=`kubectl get secret frontendadmin -n msdataworkshop --template={{.data.password}} | base64 --decode`
    // echo $FRONTEND_URL $TEST_UI_PASSWORD
    static String frontendAddress = System.getenv("FRONTEND_URL"); // eg https://129.80.106.37/"
    static final String usernameGrabdish = "grabdish";
    static final String uiPW = System.getenv("TEST_UI_PASSWORD");
    // default orderNumber
    private int orderNumber = 1234;
    // placeorder (which does placeorder + showorder) is the only option other than command (which does all of the rest)
    static final String placeorder = "placeorder";
    static final String command = "command";
    //serviceNames
    static final String order = "order";
    static final String inventory = "inventory";
    static final String supplier = "supplier";
    //command names
    static final String crashAfterInsert = "crashAfterInsert"; //on order
    static final String crashAfterOrderMessageReceived = "crashAfterOrderMessageReceived"; //on inventory
    static final String crashAfterOrderMessageProcessed = "crashAfterOrderMessageProcessed"; //on inventory
    static final String crashAfterInventoryMessageReceived = "crashAfterInventoryMessageReceived"; //on order
    static final String showorder = "showorder"; //on order
    static final String deleteallorders = "deleteallorders"; //on order
    static final String getInventory = "getInventory"; //on supplier
    static final String removeInventory = "removeInventory"; //on supplier
    static final String addInventory = "addInventory"; //on supplier


    static {
        System.out.println("TransactionalTests frontendAddress:" + frontendAddress);
    }

     HttpResponse deleteAllOrders(CloseableHttpClient httpClient) throws IOException {
        System.out.println("TransactionalTests.deleteAllOrders");
        HttpPost request = new HttpPost( frontendAddress + command);
        Command command = new Command();
        command.commandName = deleteallorders;
        command.serviceName = order;
        ObjectWriter ow = new ObjectMapper().writer().withDefaultPrettyPrinter();
        String jsonString = ow.writeValueAsString(command);
        StringEntity requestEntity = new StringEntity( jsonString, ContentType.APPLICATION_JSON);
        request.setEntity(requestEntity);
        HttpResponse httpResponse = httpClient.execute( request );
        System.out.println("TransactionalTests.deleteAllOrders httpResponse.getEntity():" + httpResponse.getEntity().getContent());
        return httpResponse;
    }

     HttpResponse crashAfterInsert(CloseableHttpClient httpClient) throws IOException {
        System.out.println("TransactionalTests.crashAfterInsert");
        HttpPost request = new HttpPost( frontendAddress + command);
        Command command = new Command();
        command.commandName = crashAfterInsert;
        command.serviceName = order;
        ObjectWriter ow = new ObjectMapper().writer().withDefaultPrettyPrinter();
        String jsonString = ow.writeValueAsString(command);
        StringEntity requestEntity = new StringEntity( jsonString, ContentType.APPLICATION_JSON);
        request.setEntity(requestEntity);
        HttpResponse httpResponse = httpClient.execute( request );
        System.out.println("TransactionalTests.crashAfterInsert httpResponse.getEntity():" + httpResponse.getEntity().getContent());
        return httpResponse;
    }

     HttpResponse placeOrder(CloseableHttpClient httpClient, boolean isAsync) throws IOException {
        System.out.println("TransactionalTests.placeOrder isAsync:" + isAsync);
        if (isAsync) { // this is for when we expect a block - todo should kill this thread/request
            Runnable runnable = () -> {
                try {
                    new TransactionalTests().placeOrder(getHttpClient(), false);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            };
            new Thread(runnable).start();
            return null;
        }
        HttpPost request = new HttpPost( frontendAddress + placeorder);
        Command command = new Command();
        command.orderId = orderNumber;
        ObjectWriter ow = new ObjectMapper().writer().withDefaultPrettyPrinter();
        String jsonString = ow.writeValueAsString(command);
        StringEntity requestEntity = new StringEntity( jsonString, ContentType.APPLICATION_JSON);
        request.setEntity(requestEntity);
        HttpResponse httpResponse = httpClient.execute( request );
        System.out.println("TransactionalTests.placeOrder httpResponse.getEntity():" + httpResponse.getEntity().getContent());
        return httpResponse;
    }

     HttpResponse showorder(CloseableHttpClient httpClient) throws IOException {
        System.out.println("TransactionalTests.showorder");
        HttpPost request = new HttpPost( frontendAddress + command);
        Command command = new Command();
        command.commandName = showorder;
        command.serviceName = order;
        command.orderId = orderNumber;
        ObjectWriter ow = new ObjectMapper().writer().withDefaultPrettyPrinter();
        String jsonString = ow.writeValueAsString(command);
        StringEntity requestEntity = new StringEntity( jsonString, ContentType.APPLICATION_JSON);
        request.setEntity(requestEntity);
        HttpResponse httpResponse = httpClient.execute( request );
        System.out.println("TransactionalTests.showorder httpResponse.getEntity():" + httpResponse.getEntity().getContent());
        return httpResponse;
    }

     CloseableHttpClient getHttpClient() throws NoSuchAlgorithmException, KeyStoreException, KeyManagementException {
        SSLContextBuilder builder = new SSLContextBuilder();
        builder.loadTrustMaterial(null, new TrustSelfSignedStrategy());
        SSLConnectionSocketFactory sslsf = new SSLConnectionSocketFactory(
                builder.build(), SSLConnectionSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);
        Registry<ConnectionSocketFactory> registry = RegistryBuilder.
                <ConnectionSocketFactory> create()
                .register("http", new PlainConnectionSocketFactory())
                .register("https", sslsf)
                .build();
        PoolingHttpClientConnectionManager cm = new PoolingHttpClientConnectionManager(registry);
        cm.setMaxTotal(2000);
        CredentialsProvider credentialsProvider = new BasicCredentialsProvider();
        credentialsProvider.setCredentials(AuthScope.ANY,
                new UsernamePasswordCredentials(usernameGrabdish, uiPW));
        return HttpClients.custom()
                .setSSLSocketFactory(sslsf)
                .setConnectionManager(cm)
                .setDefaultCredentialsProvider(credentialsProvider)
                .build();
    }

     <T> T retrieveResourceFromResponse(HttpResponse response, Class<T> clazz) throws IOException {
        String jsonFromResponse = EntityUtils.toString(response.getEntity());
        ObjectMapper mapper = new ObjectMapper()
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        return mapper.readValue(jsonFromResponse, clazz);
    }
}
