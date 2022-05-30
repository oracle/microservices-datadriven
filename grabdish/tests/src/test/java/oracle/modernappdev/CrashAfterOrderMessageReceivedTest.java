package oracle.modernappdev;

import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.util.EntityUtils;
import org.junit.jupiter.api.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;

public class CrashAfterOrderMessageReceivedTest extends TransactionalTests {

    /**
     * Transactional lab of "simplify microservices"
     * Crash the inventory service after order message is received
     * Order should be successful.
     * @throws Exception
     */
    @Test
    void testCrashAfterOrderMessageReceived() throws Exception {
        CloseableHttpClient httpClient = getCloseableHttpClientAndDeleteAllOrders();
        setInventoryToOne();
        HttpResponse httpResponse1 = setCrashType(crashAfterOrderMessageReceived);
        //assert success of request
        assertThat(httpResponse1.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        placeOrder(httpClient, false);
        //show the order (use clean/new http client)
        HttpResponse httpResponse =  showorder(getHttpClient());
        //assert success of request
        assertThat(httpResponse.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        //confirm successful order
        String jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
        System.out.println("testCrashAfterOrderMessageReceived jsonFromResponse:" + jsonFromResponse);
        while (jsonFromResponse.contains("pending")) {
            Thread.sleep(1000 * 1);
            httpResponse =  showorder(getHttpClient());
            jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
            System.out.println("testCrashAfterOrderMessageReceived jsonFromResponse:" + jsonFromResponse);
        }
        assertThat(jsonFromResponse, containsString("beer"));
        assertInventoryCount(0);
    }
}
