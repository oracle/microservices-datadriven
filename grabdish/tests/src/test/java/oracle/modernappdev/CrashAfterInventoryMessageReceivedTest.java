package oracle.modernappdev;

import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.util.EntityUtils;
import org.junit.jupiter.api.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;

public class CrashAfterInventoryMessageReceivedTest extends TransactionalTests {

    /**
     * Transactional lab of "simplify microservices"
     * Crash the order service after inventory status message is received
     * Order should be successful.
     * @throws Exception
     */
    @Test
    void testCrashAfterInventoryMessageReceived() throws Exception {
        CloseableHttpClient httpClient = getCloseableHttpClientAndDeleteAllOrders();
        setInventoryToOne();
        HttpResponse httpResponse1 = setCrashType(crashAfterInventoryMessageReceived);
        //assert success of request
        assertThat(httpResponse1.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        placeOrder(httpClient, false);
        //show the order (use clean/new http client)
        HttpResponse httpResponse =  showorder(getHttpClient());
        //assert success of request
        assertThat(httpResponse.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        //confirm successful order
        String jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
        System.out.println("testCrashAfterInventoryMessageReceived jsonFromResponse:" + jsonFromResponse);
        while (jsonFromResponse.contains("Connection refused") || jsonFromResponse.contains("pending") ) {
            Thread.sleep(1000 * 1);
            httpResponse =  showorder(getHttpClient());
            jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
            System.out.println("testCrashAfterInventoryMessageReceived jsonFromResponse:" + jsonFromResponse);
        }
        assertThat(jsonFromResponse, containsString("beer"));
        assertInventoryCount(0);
    }
}
