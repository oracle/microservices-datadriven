---
title: Uninstall
description: Unistall the Oracle BaaS from tenancy"
resources:
  - name: oci-stack-destroy
    src: "oci-stack-destroy.png"
    title: "OCI Stack Destroy"
  - name: oci-stack-destroy-logs
    src: "oci-stack-destroy-logs.png"
    title: "OCI Stack Destroy Logs"

---

To remove the Oracle Backend as a Service for Spring Cloud, in the OCI Console main menu, navigate to “Developer Services” then “Resource Manager - Stacks”. Make sure you are in the correct region and compartment where you installed the BaaS.

Click on the link to open the detail view for the Oracle Backend as a Service for Spring Cloud instance and click on the `Destroy` button to clean up resources:

<!-- spellchecker-disable -->
{{< img name="oci-stack-destroy" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

The OCI Resource Manager will use stack definition to destroy all resources.

<!-- spellchecker-disable -->
{{< img name="oci-stack-destroy-logs" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

The destroy job takes about 20 minutes to complete. You should review the logs at the end to make sure it completed succesfully. If there were any errors, in most cases running the destroy job again will fix any issues.
