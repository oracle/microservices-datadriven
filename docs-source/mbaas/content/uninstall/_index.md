---
Title: "Uninstall"
---

# Uninstall

To remove the Oracle Backend for Parse Platform, in the OCI Console main menu, navigate to **Developer Services** then **Resource Manager - Stacks**.  Make sure that you
are in the correct region and compartment where you installed the Mobile Backend as a Service (MBaaS).

Click on the link to open the detailed view for the MBaaS instance and click **Destroy** to clean up resources. For example:

![MBaaS instance details](../mbaas-destroy.png)

The destroy job takes about 20 minutes to complete.  You should review the logs at the end to make sure it completed succesfully.
If there are any errors, run the destroy job again.

Next, go to the [Release Notes](../release-notes/) page to learn more.
