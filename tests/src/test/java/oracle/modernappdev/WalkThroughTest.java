package oracle.modernappdev;

import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.util.EntityUtils;
import org.junit.jupiter.api.Test;


import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;

public class WalkThroughTest extends TestBase {

    @Test
    void testWalkThroughNoInventory() throws Exception {
        assertWalkThrough(true);
    }

    @Test
    void testWalkThroughWithInventory() throws Exception {
        assertWalkThrough(false);
    }

    private void assertWalkThrough(boolean isNoInventory) throws Exception {
        CloseableHttpClient httpClient = getCloseableHttpClientAndDeleteAllOrders();
        if (isNoInventory ) reduceInventoryToZero(); else setInventoryToOne();
        placeOrder(httpClient, false);
        //show the order (use clean/new http client)
        HttpResponse httpResponse =  showorder(getHttpClient());
        //assert success of request
        assertThat(httpResponse.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        //confirm successful order
        String jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
        System.out.println("testWalkThrough jsonFromResponse:" + jsonFromResponse);
        String lastCallResponse = "";
        while (jsonFromResponse.contains("pending") || jsonFromResponse.contains("ConnectException")) {
            Thread.sleep(1000 * 1);
            httpResponse =  lastCallResponse.equals("") ? showorder(getHttpClient()):showorderNoDebug(getHttpClient());
            jsonFromResponse = EntityUtils.toString(httpResponse.getEntity());
            if (!lastCallResponse.equals(jsonFromResponse))
                System.out.print("testWalkThrough jsonFromResponse:" + jsonFromResponse);
            else System.out.print(".");
            lastCallResponse = jsonFromResponse;
        }
        assertThat(jsonFromResponse, containsString(isNoInventory?"failed inventory does not exist":"beer"));
        assertInventoryCount(0);
    }

}
