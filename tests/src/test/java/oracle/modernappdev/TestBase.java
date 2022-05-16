package oracle.modernappdev;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;
import io.kubernetes.client.openapi.ApiClient;
import io.kubernetes.client.openapi.apis.CoreV1Api;
import io.kubernetes.client.openapi.models.*;
import io.kubernetes.client.util.Config;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
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
import org.jetbrains.annotations.NotNull;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.List;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;

public class TestBase {

    static String frontendAddress ;
    static String frontendadminSecretName = "frontendadmin";
    static String msdataworkshopns = "msdataworkshop";
    static final String usernameGrabdish = "grabdish";
    static String uiPW;
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
    static final String showorder = "showorder"; //on order
    static final String deleteallorders = "deleteallorders"; //on order
    static final String getInventory = "getInventory"; //on supplier
    static final String removeInventory = "removeInventory"; //on supplier
    static final String addInventory = "addInventory"; //on supplier


    private void setFrontendAddressFromServiceIfNeeded() throws Exception {
        if (frontendAddress!=null) return;
        ApiClient client = Config.defaultClient();
        CoreV1Api api = new CoreV1Api(client);
        V1ServiceList v1ServiceList = api.listNamespacedService(msdataworkshopns,
                null, null, null, null, null, null,
                null, null, 10, false);
        v1ServiceList.getItems().stream().forEach((service) -> processService(service));
    }

    private void processService(V1Service service) {
        if (service.getMetadata().getName().equals("ingress-nginx-controller")) {
            List<V1LoadBalancerIngress> ingress = service.getStatus().getLoadBalancer().getIngress();
            String ip = service.getStatus().getLoadBalancer().getIngress().get(0).getIp();
            System.out.println("service service.getIngress():"+ ip);
            frontendAddress = "https://" + ip + "/";
        }
    }

    private void setFrontendadminPWFromSecretIfNeeded() throws Exception {
        if (uiPW!=null) return;
        ApiClient client = Config.defaultClient();
        CoreV1Api api = new CoreV1Api(client);
        V1SecretList v1SecretList = api.listNamespacedSecret(msdataworkshopns,
                null, null, null, null, null, null,
                null, null, 10, false);
        v1SecretList.getItems().stream().forEach((secret) -> processSecret(secret));
    }

    private void processSecret(V1Secret secret) {
        if (secret.getMetadata().getName().contains(frontendadminSecretName)) {
            System.out.println("secret1 name:"+secret.getMetadata().getName());
            byte[] passwords = secret.getData().get("password");
            uiPW = new String(passwords, StandardCharsets.UTF_8);
        }
    }

    private void applyDeployment(String service) throws Exception {
        String yamlFile = "$GRABDISH_HOME/" + service + "/" + service + "-deployment.yaml";
//        Yaml yaml = new Yaml();
//        FileReader fr =new FileReader(yamlFile);
//        InputStream input = new FileInputStream(new File(yamlFile));
//        Map map = (Map) yaml.load(input);
//        V1Deployment body = yaml.loadAs(fr, V1Deployment.class);
//        ApiClient client = Config.defaultClient();
//        CoreV1Api api = new CoreV1Api(client);
//        api.cre.createNamespacedDeployment("default", body, "");

//        V1Pod pod = (V1Pod) Yaml.load(new File(yamlFile));
    }


    //END K8S, BEGIN HTTPCLIENT....

    CloseableHttpClient getHttpClient() throws Exception {
        setFrontendadminPWFromSecretIfNeeded();
        setFrontendAddressFromServiceIfNeeded();
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

    CloseableHttpClient getCloseableHttpClientAndDeleteAllOrders() throws Exception {
        CloseableHttpClient httpClient = getHttpClient();
        //delete all orders for clean run where we can use any order id
        HttpResponse httpResponse = deleteAllOrders(httpClient);
        //assert success of request
        assertThat(httpResponse.getStatusLine().getStatusCode(), equalTo(HttpStatus.SC_OK));
        return httpClient;
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
        //todo assert in pending state
        System.out.println("TransactionalTests.placeOrder httpResponse.getEntity():" + httpResponse.getEntity().getContent());
        return httpResponse;
    }

    HttpResponse deleteAllOrders(CloseableHttpClient httpClient) throws IOException {
        return servicecall(httpClient, deleteallorders, order, -1);
    }

    HttpResponse showorder(CloseableHttpClient httpClient) throws IOException {
        return servicecall(httpClient, showorder, order, orderNumber);
    }
    HttpResponse showorderNoDebug(CloseableHttpClient httpClient) throws IOException {
        return servicecall(httpClient, showorder, order, orderNumber, false);
    }

    //supplier service calls...
    HttpResponse getInventory(CloseableHttpClient httpClient) throws IOException {
        return servicecall(httpClient, getInventory, supplier, -1);
    }
    HttpResponse addInventory(CloseableHttpClient httpClient) throws IOException {
        return servicecall(httpClient, addInventory, supplier, -1);
    }
    HttpResponse removeInventory(CloseableHttpClient httpClient) throws IOException {
        return servicecall(httpClient, removeInventory, supplier, -1);
    }

    //todo we really need a "setInventoryTo(int i)" method
    HttpResponse reduceInventoryToZero() throws Exception {
        HttpResponse httpResponse;
        while (!EntityUtils.toString((httpResponse = getInventory(getHttpClient())).getEntity()).contains("0")) {
            System.out.println("TestBase.reduceInventoryToZero removeInventory");
            removeInventory(getHttpClient());
        }
        return httpResponse;
    }

    void assertInventoryCount(int inventoryCount) throws Exception {
        assertThat(EntityUtils.toString(getInventory(getHttpClient()).getEntity()),
                containsString("" + inventoryCount));
    }

    HttpResponse setInventoryToOne() throws Exception {
        CloseableHttpClient httpClient = getHttpClient();
        HttpResponse httpResponse = getInventory(httpClient);
        String entityString = EntityUtils.toString(httpResponse.getEntity());
        if (entityString.contains("1")) {
            return httpResponse;
        } else if (entityString.contains("0")) {
            return addInventory(httpClient);
        } else {
            return reduceInventoryToOne(httpClient);
        }
    }

    private HttpResponse reduceInventoryToOne(CloseableHttpClient httpClient) throws IOException {
        HttpResponse httpResponse;
        while (!EntityUtils.toString((httpResponse = getInventory(httpClient)).getEntity()).contains("1")) {
            removeInventory(httpClient);
        }
        return httpResponse;
    }


    //Calls that require only commandname and service, no params (orderid and orderitem , where application, use defaults)
    @NotNull
    private HttpResponse servicecall(CloseableHttpClient httpClient, String commandName, String serviceName, int orderId) throws IOException {
        return servicecall(httpClient, commandName, serviceName, orderId, true);
    }
    private HttpResponse servicecall(CloseableHttpClient httpClient, String commandName, String serviceName, int orderId, boolean isShowDebug) throws IOException {
        if (isShowDebug) System.out.println("servicecall serviceName:" + serviceName + " commandName:" + commandName);
                HttpPost request = new HttpPost(frontendAddress + command);
        Command command = new Command();
        command.commandName = commandName;
        command.serviceName = serviceName;
        command.orderId = orderId;
        ObjectWriter ow = new ObjectMapper().writer().withDefaultPrettyPrinter();
        String jsonString = ow.writeValueAsString(command);
        StringEntity requestEntity = new StringEntity(jsonString, ContentType.APPLICATION_JSON);
        request.setEntity(requestEntity);
        HttpResponse httpResponse = httpClient.execute(request);
        if (isShowDebug) System.out.println("servicecall serviceName:" + serviceName + " commandName:" + commandName + "  returned");
        return httpResponse;
    }
}
