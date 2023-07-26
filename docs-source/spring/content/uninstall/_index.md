---
title: Uninstall
description: Uninstall the Oracle BaaS from tenancy"
resources:
  - name: oci-stack-destroy
    src: "oci-stack-destroy.png"
    title: "OCI Stack Destroy"
  - name: oci-stack-destroy-logs
    src: "oci-stack-destroy-logs.png"
    title: "OCI Stack Destroy Logs"

---

To remove the Oracle Backend for Spring Boot, in the OCI Console main menu, navigate to “Developer Services” then “Resource Manager - Stacks”. Ensure that you are in the correct region and compartment where you installed the OBaaS.

Click on the link to open the detailed view for the Oracle Backend for Spring Boot instance and click on **Destroy** to clean up resources. For example:

<!-- spellchecker-disable -->
{{< img name="oci-stack-destroy" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

The OCI Resource Manager uses the stack definition to destroy all resources. For example:

<!-- spellchecker-disable -->
{{< img name="oci-stack-destroy-logs" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

The destroy job takes about 20 minutes to complete. Review the logs at the end to ensure that it completed successfully. If there were any errors, run the **Destroy** job again.
