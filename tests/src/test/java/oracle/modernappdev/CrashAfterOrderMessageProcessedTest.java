package oracle.modernappdev;

import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.util.EntityUtils;
import org.junit.jupiter.api.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;

public class CrashAfterOrderMessageProcessedTest  extends TransactionalTests {

    /**
     * Transactional lab of "simplify microservices" workshop
     * Crash the inventory service after order message is processed
     * Order should be successful.
     * @throws Exception
     */
    @Test
    void testCrashAfterOrderMessageProcessed() throws Exception {
        CloseableHttpClient httpClient = getCloseableHttpClientAndDeleteAllOrders();
        setInventoryToOne();
        HttpResponse httpResponse1 = setCrashType(crashAfterOrderMessageProcessed);
        //assert success of request
        assertThat(httpResponse1.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        placeOrder(httpClient, false);
        //show the order (use clean/new http client)
        HttpResponse httpResponse =  showorder(getHttpClient());
        //assert success of request
        assertThat(httpResponse.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        //confirm successful order
        String jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
        System.out.println("testCrashAfterOrderMessageProcessed jsonFromResponse:" + jsonFromResponse);
        String lastCallResponse = "";
        while (jsonFromResponse.contains("pending") || jsonFromResponse.contains("ConnectException")) {
            Thread.sleep(1000 * 1);
            httpResponse =  lastCallResponse.equals("") ? showorder(getHttpClient()):showorderNoDebug(getHttpClient());
            jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
            if (!lastCallResponse.equals(jsonFromResponse))
                System.out.println("testCrashAfterOrderMessageProcessed jsonFromResponse:" + jsonFromResponse);
            else System.out.print(".");
            lastCallResponse = jsonFromResponse;
        }
        assertThat(jsonFromResponse, containsString("beer"));
        assertInventoryCount(0);
    }

}

