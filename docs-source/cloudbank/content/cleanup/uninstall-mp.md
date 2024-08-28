+++
archetype = "page"
title = "OCI Marketplace Uninstall"
weight = 4
+++

> **Note:** These steps apply only if you chose the option to install the full stack from OCI Marketplace.

The Oracle Backend for Spring Boot and Microservices environment was deployed using ORM and Terraform.  The uninstall will use OCI Resource Manager (ORM) to Destroy the stack.

1. Navigate to OCI Resource Manager Stacks

   ![OCI ORM](../images/orm-stacks.png " ")

2. Make sure you choose the Compartment where you installed Oracle Backend for Spring Boot and Microservices. Click on the Stack Name (which will be different from the screenshot)

   ![Select Stack](../images/pick-stack.png " ")

3. After picking the stack. Click destroy. **NOTE** This will stop all resources and remove the Oracle Backend for Spring Boot and Microservices environment. The only way to get it back is to re-deploy the stack

   ![Destroy Stack](../images/destroy-stack.png " ")

4. Confirm that you want to shut down and destroy the resources

   ![Destroy Stack](../images/confirm-destroy.png " ")

If the Terraform Destroy job fails, re-run the Destroy job again after a few minutes.

### Left over resources

Even after the Destroy job has finished there will be one resource left in the tenancy/compartment and that is an OCI Vault. The Vault is on `PENDING DELETION` mode.

   ![OCI Vault](../images/vault.png " ")

