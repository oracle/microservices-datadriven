package oracle.modernappdev;

import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.util.EntityUtils;
import org.junit.jupiter.api.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;

public class CrashAfterInventoryMessageReceivedTest extends TransactionalTests {

    /**
     * Transactional lab of "simplify microservices"
     * @throws Exception
     */
    @Test
    void testCrashAfterInventoryMessageReceived() throws Exception {
        CloseableHttpClient httpClient = getHttpClient();
        //delete all orders for clean run where we can use any order id
        HttpResponse httpResponse = deleteAllOrders(httpClient);
        //assert success of request
        assertThat(httpResponse.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        //set the "crashAfterInsert" failure case
        httpResponse = crashAfterInsert(httpClient);
        //assert success of request
        assertThat(httpResponse.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        //place and order async, expecting hang due to order service crash
        placeOrder(httpClient, true);
        //sleep so that the next request is after order service restarts
        System.out.println("CrashAfterOrderInsertedBeforeMessageSentTest.testCrashAfterOrderInsertedBeforeMessageSent sleep for a minute");
        Thread.sleep(60 * 1000); //  non-deterministic but adequate
        //get a clean http client
        httpClient = getHttpClient();
        //show the order
        httpResponse = showorder(httpClient);
        //assert success of request
        assertThat(httpResponse.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        //confirm the order is null (doesnt exist) because it was rolledback
        String jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
        System.out.println("CrashAfterOrderInsertedBeforeMessageSentTest.testCrashAfterOrderInsertedBeforeMessageSent jsonFromResponse:" + jsonFromResponse);
        assertThat(jsonFromResponse, equalTo("null"));
    }
}
