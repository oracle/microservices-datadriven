---
title: "Troubleshooting"
description: "Troubleshoot Oracle Backend for Spring Boot and Microservices"
keywords: "support backend oracle springboot spring development microservices database"
---
If experiencing issues with the Oracle Backend for Spring Boot and Microservices; check here for known issues and resolutions.

# ORA-28000: The account is locked

Access the database and determine which account has been locked by running the following SQL:

```sql
SELECT USERNAME, LOCK_DATE, PROFILE FROM DBA_USERS 
 WHERE ACCOUNT_STATUS='LOCKED'
   AND AUTHENTICATION_TYPE='PASSWORD'
   AND ORACLE_MAINTAINED<>'Y';
```

Unlock the account by running: `ALTER USER <USERNAME> ACCOUNT UNLOCK;'

If the account continues to be locked, evaluate the password being used by the service and changes appropriately.