---
title: Application Database Access
sidebar_position: 2
---
## Application Database Access

:::note
This step is only necessary if your application is connecting to a database.
:::

If your application needs database access, first obtain the database user credentials. Then create a Kubernetes secret containing those credentials. The secret is referenced in your application deployment.

### Create the secret for the application

Create a secret with database access information. This secret is used by the application configuration and is injected during deployment.

For example, if you have the following information:

- `db.name:` Your database name. For example, `helmdb`
- `db.username:` Your database user name. For example, `phonebook`
- `db.password:` Your database user password. For example, `Welcome-12345`
- `db.service:` Your service name. For example, `helmdb_tp`
- `db.lb_username` Your Liquibase username.
- `db.lb_password` Your Liquibase user password.

Create a Kubernetes secret (in this example, `phonebook-db-secrets` in the `obaas-dev` namespace):

```bash
kubectl -n obaas-dev create secret generic phonebook-db-secrets \
  --from-literal=db.name=helmdb \
  --from-literal=db.username=phonebook \
  --from-literal=db.password=Welcome-12345 \
  --from-literal=db.service=helmdb_tp \
  --from-literal=db.lb_username=phonebook \
  --from-literal=db.lb_password=Welcome-12345
```

You can verify the values by running the following command (this is for the `username` value):

```bash
kubectl -n obaas-dev get secret phonebook-sb-secrets -o jsonpath='{.data.username}' | base64 -d
```

### Create database user using `sqljob.yaml` k8s job

Use this job to run SQL statements against the database with the credentials stored in the secret above.

Set the namespace to where the `obaas-db-secret` secret resides (example uses `obaas-dev`):

```yaml
metadata:
  generateName: sqlcl-runner-job-
  namespace: obaas-dev
```

Update the `args:` section with your SQL:

```yaml
args:
  - |
  export TNS_ADMIN=/etc/oracle/wallet

  # Create the SQL script inline
  cat > /tmp/run.sql << 'EOF'
  SET SERVEROUTPUT ON;
  WHENEVER SQLERROR EXIT SQL.SQLCODE;

  <<SQL STATEMENTS>>

  EXIT;
  EOF

  # Execute the SQL script
  sql $(DB_USER)/$(DB_PASSWORD)@$(TNS_ALIAS) @/tmp/run.sql
```

Update the `env:` section to reference the correct secret and keys (here using `obaas-db-secrets`; this is not the same secret as was created above):

```yaml
env:
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: obaas-db-secret
      key: db.username
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: obaas-db-secret
      key: db.password
- name: TNS_ALIAS
  valueFrom:
    secretKeyRef:
      name: obaas-db-secret
      key: db.service
```

Set the TNS Admin wallet secret name to match your OBaaS installation:

```yaml
volumes:
- name: db-wallet-volume
  secret:
    secretName: obaas-adb-tns-admin-1
```

Execute `kubectl create -f sqljob.yaml` to create the kubernetes job.

```log
job.batch/sqlcl-runner-job-2vcrq created
```

You can verify that the Job ran successfully by checking its logs.

#### Example `sqljob.yaml`

This is an example of a kubernetes job that creates a `phonebook` user and assigns roles to the user.

```yaml
# The Job to run the SQLcl container with embedded SQL
apiVersion: batch/v1
kind: Job
metadata:
  generateName: sqlcl-runner-job-
  namespace: obaas-dev
spec:
  backoffLimit: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: sqlcl-container
        image: container-registry.oracle.com/database/sqlcl:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          export TNS_ADMIN=/etc/oracle/wallet
          
          # Create the SQL script inline
          cat > /tmp/run.sql << 'EOF'
          SET SERVEROUTPUT ON;
          WHENEVER SQLERROR EXIT SQL.SQLCODE;
          
          create user if not exists phonebook identified by "Welcome-12345";
          grant db_developer_role to phonebook;
          grant unlimited tablespace to phonebook;
          commit;

          /
          EXIT;
          EOF
          
          # Execute the SQL script
          sql $(DB_USER)/$(DB_PASSWORD)@$(TNS_ALIAS) @/tmp/run.sql
        env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: obaas-db-secret
              key: db.username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: obaas-db-secret
              key: db.password
        - name: TNS_ALIAS
          valueFrom:
            secretKeyRef:
              name: obaas-db-secret
              key: db.service
        volumeMounts:
        - name: db-wallet-volume
          mountPath: /etc/oracle/wallet
          readOnly: true
      volumes:
      - name: db-wallet-volume
        secret:
          secretName: obaas-adb-tns-admin-1
```
