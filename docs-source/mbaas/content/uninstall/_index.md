
To remove the MBaaS, in the OCI Console main menu, navigate to "Developer Services" then "Resource Manager - Stacks".  Make sure you
are in the correct region and compartment where you installed the MBaaS.

Click on the link to open the detail view for the MBaaS instance and click on the "Destroy" button to clean up resources:

![MBaaS instance details](../mbaas-destroy.png)

The destroy job takes about 20 minutes to complete.  You should review the logs at the end to make sure it completed succesfully.
If there were any errors, in most cases running the destroy job again will fix any issues.
