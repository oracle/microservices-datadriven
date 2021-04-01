/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package oracle.db.microservices;

import oracle.ucp.jdbc.PoolDataSource;

import java.sql.*;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.context.Initialized;
import javax.enterprise.event.Observes;
import javax.inject.Inject;
import javax.inject.Named;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;


@Path("/")
@ApplicationScoped
public class ATPAQAdminResource {
  PropagationSetup propagationSetup;
  static String regionId = System.getenv("OCI_REGION").trim();
  static String pwSecretOcid = System.getenv("VAULT_SECRET_OCID").trim();
  static String pwSecretFromK8s = System.getenv("dbpassword");
  static String orderuser = "ORDERUSER";
  static String orderpw;
  static String inventoryuser = "INVENTORYUSER";
  static String inventorypw;
  static String orderQueueName = "ORDERQUEUE";
  static String orderQueueTableName = "ORDERQUEUETABLE";
  static String inventoryQueueName = "INVENTORYQUEUE";
  static String inventoryQueueTableName = "INVENTORYQUEUETABLE";
  static String orderToInventoryLinkName = "ORDERTOINVENTORYLINK";
  static String inventoryToOrderLinkName = "INVENTORYTOORDERLINK";
  static String cwalletobjecturi =   System.getenv("cwalletobjecturi");
  static String inventoryhostname =   System.getenv("inventoryhostname");
  static String inventoryport =   System.getenv("inventoryport");
  static String inventoryservice_name =   System.getenv("inventoryservice_name");
  static String inventoryssl_server_cert_dn =   System.getenv("inventoryssl_server_cert_dn");
  static String orderhostname =   System.getenv("orderhostname");
  static String orderport =   System.getenv("orderport");
  static String orderservice_name =   System.getenv("orderservice_name");
  static String orderssl_server_cert_dn =   System.getenv("orderssl_server_cert_dn");

  static {
    System.setProperty("oracle.jdbc.fanEnabled", "false");
    System.out.println("ATPAQAdminResource.static cwalletobjecturi:" + cwalletobjecturi);
  }

  @Inject
  @Named("orderpdb")
  private PoolDataSource orderpdbDataSource;

  @Inject
  @Named("inventorypdb")
  private PoolDataSource inventorypdbDataSource;

  public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws SQLException {
    String pw;
    if(!"".equals(pwSecretOcid.trim())) {
      System.out.println("Using OCI Vault secret");
      pw = OCISDKUtility.getSecreteFromVault(true, regionId, pwSecretOcid);
    } else {
      pw = pwSecretFromK8s;
    }
    orderpw = inventorypw = pw;
    orderpdbDataSource.setUser("ADMIN");
    orderpdbDataSource.setPassword(orderpw);
    inventorypdbDataSource.setUser("ADMIN");
    inventorypdbDataSource.setPassword(inventorypw);
  }

  PropagationSetup getPropagationSetup() {
    if(propagationSetup == null) propagationSetup = new PropagationSetup();
    return propagationSetup;
  }

  @Path("/testorderdatasource")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String testorderdatasource() {
    System.out.println("testorderdatasource...");
    try (Connection connection = orderpdbDataSource.getConnection()){
      System.out.println("ATPAQAdminResource.testdatasources orderpdbDataSource connection:" + connection );
    } catch (Exception e) {
      e.printStackTrace();
    }
    return "success";
  }

  @Path("/testdatasources")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String testdatasources() {
      System.out.println("test datasources...");
      String resultString = "orderpdbDataSource...";
    try {
      orderpdbDataSource.getConnection();
      resultString += " connection successful";
      System.out.println(resultString);
    } catch (Exception e) {
      resultString += e;
      e.printStackTrace();
    }
    resultString += " inventorypdbDataSource...";
      try {
        inventorypdbDataSource.getConnection();
        resultString += " connection successful";
        System.out.println(resultString);
      } catch (Exception e) {
        resultString += e;
          e.printStackTrace();
      }
      return resultString;
  }

  @Path("/setupAll")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String setupAll() {
    String returnValue = "";
    try {
      System.out.println("setupAll ...");
      returnValue += getPropagationSetup().createUsers(orderpdbDataSource, inventorypdbDataSource);
      returnValue += getPropagationSetup().createInventoryTable(inventorypdbDataSource);
      returnValue += getPropagationSetup().createDBLinks(orderpdbDataSource, inventorypdbDataSource);
      returnValue += getPropagationSetup().setupTablesQueuesAndPropagation(orderpdbDataSource, inventorypdbDataSource,
              true, true);
      return " result of setupAll : success... " + returnValue;
    } catch (Exception e) {
      e.printStackTrace();
      returnValue += e;
      return " result of setupAll : " + returnValue;
    }
  }

  @Path("/createUsers")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String createUsers() {
    String returnValue = "";
    try {
      System.out.println("createUsers ...");
      returnValue += getPropagationSetup().createUsers(orderpdbDataSource, inventorypdbDataSource);
      return " result of createUsers : " + returnValue;
    } catch (Exception e) {
      e.printStackTrace();
      returnValue += e;
      return " result of createUsers : " + returnValue;
    }
  }

  @Path("/createInventoryTable")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String createInventoryTable() {
    String returnValue = "";
    try {
      System.out.println("createInventoryTable ...");
      returnValue += getPropagationSetup().createInventoryTable(inventorypdbDataSource);
      return " result of createInventoryTable :  " + returnValue;
    } catch (Exception e) {
      e.printStackTrace();
      returnValue += e;
      return " result of createInventoryTable : " + returnValue;
    }
  }

  @Path("/createDBLinks")
  @GET
  @Produces(MediaType.TEXT_HTML) // does verifyDBLinks as well
  public String createDBLinks() {
    String returnValue = "";
    try {
      System.out.println("createDBLinks ...");
      returnValue += getPropagationSetup().createDBLinks(orderpdbDataSource, inventorypdbDataSource);
      return  returnValue;
    } catch (Exception e) {
      e.printStackTrace();
      returnValue += e;
      return "Exception during DBLinks create : " + returnValue;
    }
  }

  @Path("/verifyDBLinks")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String verifyDBLinks() {
    String returnValue = "";
    try {
      System.out.println("verifyDBLinks ...");
      returnValue += getPropagationSetup().verifyDBLinks(orderpdbDataSource, inventorypdbDataSource);
      return " result of verifyDBLinks :  " + returnValue;
    } catch (Exception e) {
      e.printStackTrace();
      returnValue += e;
      return " result of verifyDBLinks : " + returnValue;
    }
  }

  @Path("/setupTablesQueuesAndPropagation")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String setupTablesQueuesAndPropagation() {
    try {
      System.out.println("setupTablesQueuesAndPropagation ...");
      return getPropagationSetup().setupTablesQueuesAndPropagation(orderpdbDataSource, inventorypdbDataSource,
              true, true);
    } catch (Exception e) {
      e.printStackTrace();
      return "Setup Tables Queues And Propagation failed : " + e;
    }
  }


  @Path("/setupOrderToInventory")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String setupOrderToInventory() {
    String returnValue = "";
    return getString(returnValue, "setupOrderToInventory ...", true, false,
            " result of setupOrderToInventory :  ", " result of setupOrderToInventory : ");
  }

  @Path("/setupInventoryToOrder")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String setupInventoryToOrder() {
    String returnValue = "";
    return getString(returnValue, "setupInventoryToOrder ...", false, true,
            " result of setupInventoryToOrder :  ", " result of setupInventoryToOrder : ");
  }

  private String getString(String returnValue, String s, boolean b, boolean b2, String s2, String s3) {
    try {
      System.out.println(s);
      returnValue += getPropagationSetup().setupTablesQueuesAndPropagation(orderpdbDataSource, inventorypdbDataSource,  b, b2);
      return s2 + returnValue;
    } catch (Exception e) {
      e.printStackTrace();
      returnValue += e;
      return s3 + returnValue;
    }
  }

  @Path("/testInventoryToOrder")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String testInventoryToOrder() {
    String returnValue = "";
    try {
      System.out.println("testInventoryToOrder ...");
      returnValue += getPropagationSetup().testInventoryToOrder(orderpdbDataSource, inventorypdbDataSource);
      return " result of testInventoryToOrder :  " + returnValue;
    } catch (Exception e) {
      e.printStackTrace();
      returnValue += e;
      return " result of testInventoryToOrder : " + returnValue;
    }
  }

  @Path("/testOrderToInventory")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String testOrderToInventory() {
    String returnValue = "";
    try {
      System.out.println("testOrderToInventory ...");
      returnValue += getPropagationSetup().testOrderToInventory(orderpdbDataSource, inventorypdbDataSource);
      return " result of testOrderToInventory :  " + returnValue;
    } catch (Exception e) {
      e.printStackTrace();
      returnValue += e;
      return " result of testOrderToInventory : " + returnValue;
    }
  }

  @Path("/enablePropagation")
  @GET
  @Produces(MediaType.TEXT_PLAIN)
  public Response enablePropagation() {
    System.out.println("ATPAQAdminResource.enablePropagation");
    String returnString =  getPropagationSetup().enablePropagation(
            orderpdbDataSource, orderuser, orderpw, orderQueueName, orderToInventoryLinkName);
    returnString +=  getPropagationSetup().enablePropagation(
            inventorypdbDataSource, inventoryuser, inventorypw, inventoryQueueName, inventoryToOrderLinkName);
    return Response.ok()
            .entity("enablePropagation:" + returnString)
            .build();
  }

  @Path("/enablePropagationInventoryToOrder")
  @GET
  @Produces(MediaType.TEXT_PLAIN)
  public Response enablePropagationInventoryToOrder()  {
    System.out.println("ATPAQAdminResource.enablePropagationInventoryToOrder");
    String returnString =  getPropagationSetup().enablePropagation(
            inventorypdbDataSource, inventoryuser, inventorypw, inventoryQueueName, inventoryToOrderLinkName);
    return Response.ok()
            .entity("enablePropagationInventoryToOrder:" + returnString)
            .build();
  }

  @Path("/unschedulePropagation")
  @GET
  @Produces(MediaType.TEXT_PLAIN)
  public Response unschedulePropagation()  {
    System.out.println("ATPAQAdminResource.unschedulePropagation");
    String returnString =  getPropagationSetup().unschedulePropagation(
            orderpdbDataSource, orderuser, orderpw, orderQueueName, orderToInventoryLinkName);
    returnString +=  getPropagationSetup().unschedulePropagation(
            inventorypdbDataSource, inventoryuser, inventorypw, inventoryQueueName, inventoryToOrderLinkName);
    return Response.ok()
            .entity("unschedulePropagation:" + returnString)
            .build();
  }

  @Path("/deleteUsers")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String deleteUsers() {
    String returnValue = "";
    try {
      System.out.println("deleteUsers ...");
      returnValue += getPropagationSetup().deleteUsers(orderpdbDataSource, inventorypdbDataSource);
      return " result of deleteUsers : " + returnValue;
    } catch (Exception e) {
      e.printStackTrace();
      returnValue += e;
      return " result of deleteUsers : " + returnValue;
    }
  }

  @Path("/getConnectionMetaData")
  @GET
  @Produces(MediaType.TEXT_PLAIN)
  public Response getConnectionMetaData() throws SQLException {
    Response returnValue;
    try (Connection connection = orderpdbDataSource.getConnection()) {
      returnValue = Response.ok()
              .entity("Connection obtained successfully metadata:" + connection.getMetaData())
              .build();
    }
    return returnValue;
  }


}
