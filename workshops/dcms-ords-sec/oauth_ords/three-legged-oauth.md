
# Protect REST API with Oauth

In this lab you will protect the an REST endpoint using OAuth.

## Assumptions

* Oracle REST Data Services is deployed
* Retrieve the LB IP Address by executing the following commands from the workshop directory:

```bash
<copy>
source ./terraform-env.sh;
export LB=$(terraform output -json lb_address | jq -r '.'); echo $LB;
</copy>
```

The output should be the IP Address of the loadbalancer. SQLcl needs to be installed if local development (SQL Developer Web is a great alternative!)

## Task 1: Initial Setup

Connect to the database either using SQL Developer Web (preferred method) or the SSH Tunnel and SQLcl from your local machine. Follow the [bastion document](../bastion.md).

These steps should be performed in database as ADMIN (Autonomous Database) user.

1. Create a new Database User

    ```sql
    <copy>
    CREATE USER "ORDSTEST" IDENTIFIED BY "Welcome1234#";
    GRANT "CONNECT" TO "ORDSTEST";
    GRANT "RESOURCE" TO "ORDSTEST";
    ALTER USER "ORDSTEST" QUOTA UNLIMITED ON DATA; 
    </copy>
    ```

2. Enable User for REST as SYS/ADMIN

    ```sql
    <copy>
    BEGIN
      ORDS.enable_schema(
         p_enabled             => TRUE
        ,p_schema              => 'ORDSTEST'
        ,p_url_mapping_type    => 'BASE_PATH'
        ,p_url_mapping_pattern => 'ordstest'
        ,p_auto_rest_auth      => FALSE
      );  
      COMMIT;
    END;
    /
    </copy>
    ```

3. Create and populate a table

    ```sql
    <copy>
    CREATE TABLE ORDSTEST.EMP (
      EMPNO    NUMBER(4,0)
      ,ENAME    VARCHAR2(10 BYTE)
      ,JOB      VARCHAR2(9 BYTE)
      ,MGR      NUMBER(4,0)
      ,HIREDATE DATE
      ,SAL      NUMBER(7,2)
      ,COMM     NUMBER(7,2)
      ,DEPTNO   NUMBER(2,0) 
      ,CONSTRAINT PK_EMP PRIMARY KEY (EMPNO)
    );

    INSERT into ORDSTEST.EMP 
    VALUES (7369,'SMITH','CLERK',7902,to_date('17-DEC-80','DD-MON-RR'),800,null,20);
    
    INSERT into ORDSTEST.EMP 
    VALUES (7499,'ALLEN','SALESMAN',7698,to_date('20-FEB-81','DD-MON-RR'),1600,300,30);
    
    INSERT into ORDSTEST.EMP 
    VALUES (7521,'WARD','SALESMAN',7698,to_date('22-FEB-81','DD-MON-RR'),1250,500,30);
    
    INSERT into ORDSTEST.EMP 
    VALUES (7566,'JONES','MANAGER',7839,to_date('02-APR-81','DD-MON-RR'),2975,null,20);
    COMMIT;
    </copy>
    ```

## Task 2: Setup a RESTful Resource

These steps should be performed in database as the ORDSTEST user. Logout from SQL Developer Web or SQLcl and login again as the ORDSTEST user created in Task #1

### 1. Create a Resource

This code creates the /examples/employees/ resource, which will be protected with a privilege in a later step.

```sql
    <copy>
    BEGIN
      ORDS.DEFINE_SERVICE(
         P_MODULE_NAME    => 'examples.employees' 
        ,P_BASE_PATH      => '/examples/employees/'
        ,P_PATTERN        =>  '.' 
        ,P_ITEMS_PER_PAGE => 7
        ,P_SOURCE         =>  'SELECT * FROM EMP ORDER BY EMPNO DESC'
      );
      COMMIT;
    EXCEPTION WHEN DUP_VAL_ON_INDEX THEN 
      DBMS_OUTPUT.PUT_LINE('Service already exists');
    END;
    /
    </copy>
```

### 2. Verify the resources components

Verify Modules by running the SQL statement:

```sql
    <copy>
    SELECT id, name, uri_prefix
      FROM user_ords_modules
     ORDER BY name;
    </copy>
```

Example Output:

```text
    ID    NAME               URI_PREFIX           
    ----- ------------------ -------------------- 
    10030 examples.employees /examples/employees/
```

* **Verify Templates**

    ```sql
    <copy>
    SELECT id, module_id, uri_template
      FROM user_ords_templates
     ORDER BY module_id;
    </copy>
    ```

    Example Output:

    ```text
    ID    MODULE_ID URI_TEMPLATE 
    ----- --------- ------------ 
    10031     10030 .           
    ```

* **Verify Handlers**

    ```sql
    <copy>
    SELECT id, template_id, source_type, method, source
      FROM user_ords_handlers
     ORDER BY id;
    </copy> 
    ```

    Example Output:

    ```text
    ID    TEMPLATE_ID SOURCE_TYPE     METHOD SOURCE                                
    ----- ----------- --------------- ------ ------------------------------------- 
    10032       10031 json/collection GET    SELECT * FROM EMP ORDER BY EMPNO DESC 
    ```

### 3. Test REST service without Authentication

  The RESTful Resource should now be accessible without any authentication. Let's try in three ways.

  You can test the REST resource by using **curl** command (note that you need the Load Balancer IP to do the tests). All the tests should succeed and return the data from the EMP table in JSON format with no authentication.

  ```bash
  <copy>
  curl -k -0 -i https://${LB}/ords/ordstest/examples/employees/
  </copy> 
  ```

* Test using **Database Actions** home page:

  * Login into SQL Developer Web
  * Click on the REST Button
    ![REST Button](images/rest_button.png " ")
  * Click on the Modules Button
    ![Modules Button](images/module_button.png " ")
  * You will now see the URL to access the REST resource, you can test by clicking on the one in new tab button
    ![URL Button](images/rest_url.png " ")

  * Test through **Postman**
    * Start Postman and copy the URL for the RESTful resource and click Send:
        ![Postman](images/postman.png " ")

## Task 3: AuthN Resource Protection

In this task we'll setup the resource access protection. These steps should be performed in database as the ORDSTEST user using SQL Developer Web or SQLcl locally using the SSH Tunnel.

### 1. **Create role**

```sql
    <copy>
    BEGIN
      ORDS.CREATE_ROLE('HR Administrator');     
    END;
    /
    </copy>
```

### 2. **Verify Role**

```sql
    <copy>
    SELECT id, name
      FROM user_ords_roles
    WHERE created_by = 'ORDSTEST';
    </copy>
```

Example Output:

```text
    ID    NAME             
    ----- ---------------- 
    10033 HR Administrator
```

### 3. **Create Privilege**

```sql
    <copy>
    BEGIN
      ORDS.CREATE_PRIVILEGE(
         P_NAME        => 'example.employees'
        ,P_ROLE_NAME   => 'HR Administrator'
        ,P_LABEL       => 'Employee Data'
        ,P_DESCRIPTION => 'Provide access to employee HR data'
      );
      COMMIT;
    END;
    /
    </copy>
```

### 4. **Verify Privilege**

```sql
    <copy>
    SELECT id, name, description
      FROM user_ords_privileges
    WHERE created_by = 'ORDSTEST';
    </copy>
```

Example Output:

```text
    ID    NAME              DESCRIPTION                        
    ----- ----------------- ---------------------------------- 
    10034 example.employees Provide access to employee HR data 
```

### 5. **Associate the privilege with resources**

```sql
    <copy>
    BEGIN
      ORDS.CREATE_PRIVILEGE_MAPPING(
         p_privilege_name => 'example.employees'
        ,p_pattern        => '/examples/employees/*'
      );     
      COMMIT;
    END;
    /
    </copy>
```

### 6. **Verify Mapping**

```sql
    <copy>
    SELECT privilege_id, name, pattern 
      FROM user_ords_privilege_mappings
    WHERE created_by = 'ORDSTEST';
    </copy>
```

**NOTE**: it should be shown the result:

```text
    PRIVILEGE_ID NAME              PATTERN               
    ------------ ----------------- --------------------- 
           10034 example.employees /examples/employees/* 
```

### 7. **Setup Resource Access Protection (Fail Case)**

The RESTful Resource should now be protected. Run a curl test:

```bash
    <copy>
    curl -k -0 -i https://${LB}/ords/ordstest/examples/employees/
    </copy>
```

The curl should fail with a `401 Unauthorized` Error

```text
    HTTP/1.1 401 Unauthorized
    Date: Wed, 15 Jun 2022 17:39:38 GMT
    Content-Type: application/problem+json
    Content-Length: 183
    Connection: close
```

## Task 4: Setup First Party AuthN

### 1. Login into the ORDS Server using the SSH Forwarding command

Make sure that you are in the directory where the terraform code lives. Get access the ORDS via the SSH Tunnel (and Bastion Service) by executing the following commands:

```bash
  <copy>
  SSH_ords=$(terraform output -json bastion_ssh_cmd | jq -r '.');
  eval "$SSH_ords"
  </copy>
```

### 2. On the ORDS server, create a 3 test users

The users will must have the **HR Administrator** role. Create the users by executing the following commands for **hr_admin**[1,2]:
  
```bash
  <copy>
  sudo su - oracle
  ords --config /home/oracle/ords/config config user add "hr_admin" "HR Administrator"
  </copy>
 ```

```bash
  <copy>
  ords --config /home/oracle/ords/config config user add "hr_admin1" "HR Administrator"
  </copy>
```

```bash
  <copy>
  ords --config /home/oracle/ords/config config user add "hr_admin2" "HR Administrator"
  </copy>
```

For example:

```bash
  [opc@at-ords-core ~]$ sudo su - oracle
  Last login: Wed Jun 15 17:25:18 GMT 2022 on pts/0
  -bash-4.2$ ords --config /home/oracle/ords/config config user add "hr_admin" "HR Administrator"

  ORDS: Release 22.1 Production on Wed Jun 15 17:27:10 2022

  Copyright (c) 2010, 2022, Oracle.

  Configuration:
  /home/oracle/ords/config/

  Enter the password for hr_admin:
  Confirm password:
  Created user hr_admin in file /home/oracle/ords/config/global/credentials
```

  Make sure you remember the password it's going to be used later.

**NOTE**:

### 3. Check if user has been added

```bash
<copy>
ords --config /home/oracle/ords/config config user list
</copy>
```

you should see:

```text
Users       Roles
--------    ----------------
hr_admin    HR Administrator
hr_admin1   HR Administrator
hr_admin2   HR Administrator
```

### 4. Exit the oracle user and restart the ORDS server

Execute the following commands to restart the ORDS Server:

```bash
<copy>
exit
sudo systemctl restart ords.service
</copy>
```

### 5. Test First Party AuthN Test

```bash
<copy>
curl -i -k --user hr_admin:<HR_ADMIN_PASSWORD> https://${LB}/ords/ordstest/examples/employees/
</copy>
```

The output should be the EMP data in JSON format.

## Task 5: Setup Third Party OAuth 2.0-Based AuthN

### 1. Register the OAuth Client. These steps should be performed in database as the ORDSTEST user

```sql
    <copy>
    BEGIN 
      OAUTH.CREATE_CLIENT(
         p_name            => 'Client Credentials Example'
        ,p_grant_type      => 'client_credentials'
        ,p_privilege_names => 'example.employees'
        ,p_support_email   => 'support@example.com'
      );
      COMMIT;
    END;
    /
    </copy>
```

* **Verify**

```sql
    <copy>
    SELECT client_id,client_secret 
      FROM user_ords_clients 
    WHERE name = 'Client Credentials Example';
    </copy>
```

Example Output:

```text
    CLIENT_ID                CLIENT_SECRET            
    ------------------------ ------------------------ 
    MyskbM4pxgB4Q1U00Ui99g.. PAAbXI6wdzb_m0DcIi6Zxg.. 
```

The CLIENT\_ID and CLIENT\_SECRET values represent the secret credentials for the OAuth client.
These values must be noted and kept secure. You will use them later. You can think of them as the userid and password for the client application.

### 2. Grant the OAuth client a required ROLE

```sql
    <copy>
    BEGIN 
      OAUTH.GRANT_CLIENT_ROLE(
         'Client Credentials Example'
        ,'HR Administrator'
      );
      COMMIT;
    END;
    /
    </copy>
```

* **Verify**

```sql
    <copy>
    SELECT * 
      FROM user_ords_client_roles 
    WHERE client_name = 'Client Credentials Example';
    </copy>
```

Example Output. The results should be:

```text
    CLIENT_ID CLIENT_NAME                ROLE_ID ROLE_NAME        
    --------- -------------------------- ------- ---------------- 
        10037 Client Credentials Example   10033 HR Administrator 
```

### 3. **Test Third Party OAuth 2.0-Based AuthN**

#### 3.1 Obtain the OAuth access token using client credentials

Request an access token from the token endpoint. Replace CLIENT\_ID and CLIENT\_SECRET with the information you have from the SQL query in an earlier step.

```bash
    <copy>
    curl -k -0 -i --user <CLIENT_ID>:<CLIENT_SECRET> --data "grant_type=client_credentials" https://${LB}/ords/ordstest/oauth/token
    </copy>
```

Output should look similar to:

```bash
    curl -k -i --user MyskbM4pxgB4Q1U00Ui99g..:PAAbXI6wdzb_m0DcIi6Zxg.. --data "grant_type=client_credentials" https://129.159.74.36/ords/ordstest/oauth/token
    HTTP/1.1 200 OK
    Date: Wed, 15 Jun 2022 17:51:06 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive
    X-Frame-Options: SAMEORIGIN

    {"access_token":"eUSBOqI47Pt7jI_hmfJjPQ","token_type":"bearer","expires_in":3600}
```

In the preceding output, the access token is of type bearer, and the value is specified by the access\_token field. This value will be different for every request. The expires\_in value indicates the number of seconds until the access token expires; in this case the token will expire in one hour (3600 seconds).

#### 3.2 Access a protected resource using the access token

Execute the following cURL command, replacing ACCESS_TOKEN with the token from Step 1.

```bash
    <copy>
    curl -k -0 -i -H"Authorization: Bearer <ACCESS_TOKEN>" https://${LB}/ords/ordstest/examples/employees/
    </copy>
```

Output should be similar to:

```bash
    curl -k -0 -i -H"Authorization: Bearer eUSBOqI47Pt7jI_hmfJjPQ" https://129.159.74.36/ords/ordstest/examples/employees/
    HTTP/1.1 200 OK
    Date: Wed, 15 Jun 2022 17:55:15 GMT
    Content-Type: application/json
    Connection: close
    ETag: "vSYVPUDp2Dey6jO6ba1r7Y4mZFadlDM8FAXhRQrli2Yh6Wp1a67gDfnKNEPoxJi5jR5qWPMJUGINNjpru3VEgQ=="

    {"items":[{"empno":7566,"ename":"JONES","job":"MANAGER","mgr":7839,"hiredate":"1981-04-02T00:00:00Z","sal":2975,"comm":null,"deptno":20},{"empno":7521,"ename":"WARD","job":"SALESMAN","mgr":7698,"hiredate":"1981-02-22T00:00:00Z","sal":1250,"comm":500,"deptno":30},{"empno":7499,"ename":"ALLEN","job":"SALESMAN","mgr":7698,"hiredate":"1981-02-20T00:00:00Z","sal":1600,"comm":300,"deptno":30},{"empno":7369,"ename":"SMITH","job":"CLERK","mgr":7902,"hiredate":"1980-12-17T00:00:00Z","sal":800,"comm":null,"deptno":20}],"hasMore":false,"limit":7,"offset":0,"count":4,"links":[{"rel":"self","href":"https://129.159.74.36/ords/ordstest/examples/employees/"},{"rel":"describedby","href":"https://129.159.74.36/ords/ordstest/metadata-catalog/examples/employees/"},{"rel":"first","href":"https://129.159.74.36/ords/ordstest/examples/employees/"}]}
```

## Task 6: Setup Three-Legged OAuth 2.0-Based AuthN

Three-legged OAuth flows involve three parties: the party calling the RESTful API, the party providing the RESTful API, and an end user party that owns or manages the data to which the RESTful API provides access. Three-legged flows are used in client to server interactions where an end user must approve access to the RESTful API. In OAuth 2.0 the authorization code flow and the implicit flow are three-legged flows. These flows are typically used in business to consumer scenarios.

In this step, use the hr_admin credentials created in the **First Party Authentication** step.  Clear your browser cookies for the ORDS domain or use a different browser.

### 1. Register the client for authorization code

These steps should be performed in database as the ORDSTEST user. Replace LOADBALANCER_IP with the correct IP for the loadbalancer (`echo $LB` should give you the IP Address).

```sql
    <copy>
    BEGIN
      OAUTH.CREATE_CLIENT(
        p_name            => 'Authorization Code Example'
        ,p_grant_type      => 'authorization_code'
        ,p_owner           => 'Example Inc.'
        ,p_description     => 'Sample for demonstrating Authorization Code Flow'
        ,p_redirect_uri    => 'http://[LOADBALANCER_IP]/auth/code/example/'
        ,p_support_email   => 'support@example.org'
        ,p_support_uri     => 'http://example.org/support'
        ,p_privilege_names => 'example.employees'
      );
      COMMIT;
    END;
    /
    </copy>
```

* **Verify**

Retrieve the ClientID and ClientSecret. Note that these values are different for the ones used before.

```sql
      <copy>
      SELECT client_id, client_secret 
        FROM user_ords_clients 
      WHERE name = 'Authorization Code Example';
      </copy>
```

Example output:

```text
    ID    CLIENT_ID                CLIENT_SECRET            
    ----- ------------------------ ------------------------ 
    10046 aFsQ76cbIBG2mBFw_EtcTA.. QH9yBVdzg2fUL7rr0FUEDQ.. 
```

### 2. Test Three-Legged OAuth 2.0-Based AuthN

To grant access to the privilege, an end user must approve access. The CLIENT\_ID and CLIENT\_SECRET obtained in the previous step values represent the secret credentials for the OAuth client. These values must be noted and kept secure. You can think of them as the userid and password for the client application.

This major step involves several substeps. (You must have already created the HR\_ADMIN end user in a previous step.)

#### 2.1 Obtain an OAuth authorization code

The end user will be prompted (via a web page) to sign in and approve access to the third party application. The third party application initiates this process by directing the user to the OAuth Authorization Endpoint. For Oracle REST Data Services, the path of the authorization endpoint is always oauth/auth, relative to the root path of the schema being accessed. The token endpoint for this example is where the CLIENT_ID needs to be replace with the values retrieved in the SQL query above. (The state value is is a random value):

```text
https://[LOADBALANCER_IP]/ords/ordstest/oauth/auth?response_type=code&client_id=<CLIENT_ID>&state=3668D7A713E93372E0406A38A8C02171
```

* You will be presented with a webpage and a 401 error. Click on the **sign in** link to sign in as ht hr_admin user.

    ![401_login](images/401_signin.png " ")

* If the client\_id is recognized, then a sign in prompt is displayed. Enter the credentials of the HR\_ADMIN end user, and click **Sign In**.

    ![login](images/login.png " ")

* On the the next page click **Approve**:

    ![approve](images/approve.png " ")

This will cause a redirect to redirect URI specified when the client was registered. The redirect URI will include the authorization code in the query string portion of the URI. It will also include the same state parameter value that the client provided at the start of the flow. The redirect URI will look like the following:

```text
http://[LOADBALANCER_IP]/auth/code/example/?code=Y7ue-kEO7jZV6HgLU4vkaw&state=3668D7A713E93372E0406A38A8C02171
```

![URL_sample](images/url_sample.png " ")

The client application must verify the value of the state parameter and then note the value of the code parameter, which will be used in to obtain an access token.

### 2.2 Obtain an OAuth access token

After the third party application has an authorization code, it must exchange it for an access token. The third party application's server must make a HTTPS request to the Token Endpoint. You can mimic the server making this request by using a cURL command as in the following example (replace CLIENT\_ID, CLIENT\_SECRET and AUTHORIZATION\_CODE with values you have saved from previous steps):

```bash
    <copy>
    curl -k -0 --user <CLIENT_ID>:<CLIENT_SECRET> --data "grant_type=authorization_code&code=<AUTHORIZATION_CODE>" https://${LB}/ords/ordstest/oauth/token
    </copy>
```

In the preceding command, replace clientId with the value of the CLIENT\_ID shown in USER\_ORDS\_CLIENTS for Authorization Code Example, replace clientSecret with the value of the CLIENT\_SECRET shown in USER\_ORDS\_CLIENTS for Authorization Code Example, and replace authorizationCode with the value of the authorization code noted in a previous step (the value of the code parameter).

The result should be similar to the following:

```bash
    curl -k -0 --user DVHHUNCKrjPghK070gBFIQ..:56PihGkeZDCv_3khcSNvuw.. --data "grant_type=authorization_code&code=ekuTAW-eroX1bdSmMi7X2A" https://129.159.74.36/ords/ordstest/oauth/token
    {"access_token":"L-RxBvjACN-F029kIv-5qQ","token_type":"bearer","expires_in":3600,"refresh_token":"z2_ToaMJOiW6JiBav7zzLQ"
```

In the preceding result, the access token is specified by the access_token field, and a refresh token is specified by the refresh\_token field. This refresh token value can be used to extend the user session without requiring the user to reauthorize the third party application.

### 2.3 Access a protected resource using the access token

After the third party application has obtained an OAuth access token, it can use that access token to access the protected /examples/employees/ resource. Replace <\ACCESS_TOKEN\> with the access token presented in the previous step:

```bash
    <copy>
    curl -k -0 -i -H"Authorization: Bearer <ACCESS_TOKEN>" https://${LB}/ords/ordstest/examples/employees/
    </copy>
```

For example:

```bash
    curl -k -0 -i -H"Authorization: Bearer L-RxBvjACN-F029kIv-5qQ" https://129.159.74.36/ords/ordstest/examples/employees/
    HTTP/1.1 200 OK
    Date: Wed, 15 Jun 2022 18:17:13 GMT
    Content-Type: application/json
    Connection: close
    ETag: "vSYVPUDp2Dey6jO6ba1r7Y4mZFadlDM8FAXhRQrli2Yh6Wp1a67gDfnKNEPoxJi5jR5qWPMJUGINNjpru3VEgQ=="

    {"items":[{"empno":7566,"ename":"JONES","job":"MANAGER","mgr":7839,"hiredate":"1981-04-02T00:00:00Z","sal":2975,"comm":null,"deptno":20},{"empno":7521,"ename":"WARD","job":"SALESMAN","mgr":7698,"hiredate":"1981-02-22T00:00:00Z","sal":1250,"comm":500,"deptno":30},{"empno":7499,"ename":"ALLEN","job":"SALESMAN","mgr":7698,"hiredate":"1981-02-20T00:00:00Z","sal":1600,"comm":300,"deptno":30},{"empno":7369,"ename":"SMITH","job":"CLERK","mgr":7902,"hiredate":"1980-12-17T00:00:00Z","sal":800,"comm":null,"deptno":20}],"hasMore":false,"limit":7,"offset":0,"count":4,"links":[{"rel":"self","href":"https://129.159.74.36/ords/ordstest/examples/employees/"},{"rel":"describedby","href":"https://129.159.74.36/ords/ordstest/metadata-catalog/examples/employees/"},{"rel":"first","href":"https://129.159.74.36/ords/ordstest/examples/employees/"}]}
```

## Learn More

* Ask for help and connect with developers on the [Oracle DB Microservices Slack Channel](https://bit.ly/oracle-database-microservices-slack).  Search for and join the `oracle-db-microservices` channel.

## Acknowledgements

* **Author** - Andy Tael, Developer Evangelist;
               Corrado De Bari, Developer Evangelist
* **Contributors** - John Lathouwers, Developer Evangelist
* **Last Updated By/Date** - Andy Tael, July 2022
