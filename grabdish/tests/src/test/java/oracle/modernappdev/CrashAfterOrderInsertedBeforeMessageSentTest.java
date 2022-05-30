package oracle.modernappdev;

import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.util.EntityUtils;
import org.junit.jupiter.api.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;

public class CrashAfterOrderInsertedBeforeMessageSentTest extends TransactionalTests {

    /**
     * Transactional lab of "simplify microservices"
     * Crash the order service after order is inserted and before message is sent to inventory service
     * Order should rollback.
     * @throws Exception
     */
    @Test
    void testCrashAfterOrderInsertedBeforeMessageSent() throws Exception {
        CloseableHttpClient httpClient = getCloseableHttpClientAndDeleteAllOrders();
        setInventoryToOne();
        //set the "crashAfterInsert" failure case
        HttpResponse httpResponse = setCrashType(crashAfterInsert);
        //assert success of request
        assertThat(httpResponse.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        //place and order async, expecting hang due to order service crash
        placeOrder(httpClient, true);
        //sleep so that the next request is after order service restarts
        System.out.println("CrashAfterOrderInsertedBeforeMessageSentTest.testCrashAfterOrderInsertedBeforeMessageSent sleep for a minute");
        Thread.sleep(60 * 1000); //  non-deterministic but if exceed also indicates and issue we should look into
        //show the order (use clean/new http client)
        httpResponse = showorder(getHttpClient());
        //assert success of request
        assertThat(httpResponse.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        //confirm the order is null (doesnt exist) because it was rolledback
        String jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
        while (jsonFromResponse.contains("Connection refused")) {
            Thread.sleep(1000 * 1);
            httpResponse =  showorder(getHttpClient());
            jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
            System.out.println("testCrashAfterOrderMessageReceived jsonFromResponse:" + jsonFromResponse);
        }
        System.out.println("CrashAfterOrderInsertedBeforeMessageSentTest.testCrashAfterOrderInsertedBeforeMessageSent jsonFromResponse:" + jsonFromResponse);
        assertThat(jsonFromResponse, equalTo("null")); // null means rolledback
        assertInventoryCount(1);
    }
}
