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
import javax.sql.DataSource;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;


@Path("/")
@ApplicationScoped
public class ATPAQAdminResource {
  PropagationSetup propagationSetup;
  static String regionId = System.getenv("OCI_REGION").trim();
  static String pwSecretOcid = System.getenv("VAULT_SECRET_OCID").trim();
  static String travelagencyuser = "ORDERUSER";
  static String travelagencypw;
  static String participantuser = "INVENTORYUSER";
  static String participantpw;
  static String travelagencyQueueName = "ORDERQUEUE";
  static String travelagencyQueueTableName = "ORDERQUEUETABLE";
  static String participantQueueName = "INVENTORYQUEUE";
  static String participantQueueTableName = "INVENTORYQUEUETABLE";
  static String travelagencyToInventoryLinkName = "ORDERTOINVENTORYLINK";
  static String participantToOrderLinkName = "INVENTORYTOORDERLINK";
  static String cwalletobjecturi =   System.getenv("cwalletobjecturi");
  static String participanthostname =   System.getenv("participanthostname");
  static String participantport =   System.getenv("participantport");
  static String participantservice_name =   System.getenv("participantservice_name");
  static String participantssl_server_cert_dn =   System.getenv("participantssl_server_cert_dn");
  static String travelagencyhostname =   System.getenv("travelagencyhostname");
  static String travelagencyport =   System.getenv("travelagencyport");
  static String travelagencyservice_name =   System.getenv("travelagencyservice_name");
  static String travelagencyssl_server_cert_dn =   System.getenv("travelagencyssl_server_cert_dn");

  static {
    System.setProperty("oracle.jdbc.fanEnabled", "false");
    System.out.println("ATPAQAdminResource.static cwalletobjecturi:" + cwalletobjecturi);
  }

  @Inject
  @Named("travelagencypdb")
  private PoolDataSource travelagencypdbDataSource;

  @Inject
  @Named("participantpdb")
  private PoolDataSource participantpdbDataSource;

  public void init(@Observes @Initialized(ApplicationScoped.class) Object init) throws SQLException {
    System.out.println("ATPAQAdminResource.init " + init);
    travelagencypw = participantpw = OCISDKUtility.getSecreteFromVault(true, regionId, pwSecretOcid);
    travelagencypdbDataSource.setUser("ADMIN");
    travelagencypdbDataSource.setPassword(travelagencypw);
    participantpdbDataSource.setUser("ADMIN");
    participantpdbDataSource.setPassword(participantpw);
  }

  PropagationSetup getPropagationSetup() {
    if(propagationSetup == null) propagationSetup = new PropagationSetup();
    return propagationSetup;
  }

  @Path("/testtravelagencydatasource")
  @GET
  @Produces(MediaType.TEXT_HTML)
  public String testtravelagencydatasource() {
    System.out.println("testtravelagencydatasource...");
    try (Connection connection = travelagencypdbDataSource.getConnection()){
      System.out.println("ATPAQAdminResource.testdatasources travelagencypdbDataSource connection:" + connection );
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
      String resultString = "travelagencypdbDataSource...";
    try {
      travelagencypdbDataSource.getConnection();
      resultString += " connection successful";
      System.out.println(resultString);
    } catch (Exception e) {
      resultString += e;
      e.printStackTrace();
    }
    resultString += " participantpdbDataSource...";
      try {
        participantpdbDataSource.getConnection();
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
      returnValue += getPropagationSetup().createUsers(travelagencypdbDataSource, participantpdbDataSource);
      returnValue += getPropagationSetup().createInventoryTable(participantpdbDataSource);
      returnValue += getPropagationSetup().createDBLinks(travelagencypdbDataSource, participantpdbDataSource);
      returnValue += getPropagationSetup().setupTablesQueuesAndPropagation(travelagencypdbDataSource, participantpdbDataSource,
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
      returnValue += getPropagationSetup().createUsers(travelagencypdbDataSource, participantpdbDataSource);
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
      returnValue += getPropagationSetup().createInventoryTable(participantpdbDataSource);
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
      returnValue += getPropagationSetup().createDBLinks(travelagencypdbDataSource, participantpdbDataSource);
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
      returnValue += getPropagationSetup().verifyDBLinks(travelagencypdbDataSource, participantpdbDataSource);
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
      return getPropagationSetup().setupTablesQueuesAndPropagation(travelagencypdbDataSource, participantpdbDataSource,
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
      returnValue += getPropagationSetup().setupTablesQueuesAndPropagation(travelagencypdbDataSource, participantpdbDataSource,  b, b2);
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
      returnValue += getPropagationSetup().testInventoryToOrder(travelagencypdbDataSource, participantpdbDataSource);
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
      returnValue += getPropagationSetup().testOrderToInventory(travelagencypdbDataSource, participantpdbDataSource);
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
            travelagencypdbDataSource, travelagencyuser, travelagencypw, travelagencyQueueName, travelagencyToInventoryLinkName);
    returnString +=  getPropagationSetup().enablePropagation(
            participantpdbDataSource, participantuser, participantpw, participantQueueName, participantToOrderLinkName);
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
            participantpdbDataSource, participantuser, participantpw, participantQueueName, participantToOrderLinkName);
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
            travelagencypdbDataSource, travelagencyuser, travelagencypw, travelagencyQueueName, travelagencyToInventoryLinkName);
    returnString +=  getPropagationSetup().unschedulePropagation(
            participantpdbDataSource, participantuser, participantpw, participantQueueName, participantToOrderLinkName);
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
      returnValue += getPropagationSetup().deleteUsers(travelagencypdbDataSource, participantpdbDataSource);
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
    try (Connection connection = travelagencypdbDataSource.getConnection()) {
      returnValue = Response.ok()
              .entity("Connection obtained successfully metadata:" + connection.getMetaData())
              .build();
    }
    return returnValue;
  }


}
