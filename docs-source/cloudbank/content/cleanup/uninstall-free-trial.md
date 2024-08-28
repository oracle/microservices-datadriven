+++
archetype = "page"
title = "OCI Free Tier Cleanup"
weight = 3
+++


> **Note:** These steps apply only if you chose the option to install in OCI Free Tier.

1. Login into your OCI Free Trail account.

1. Delete the Compute Instance.

    * Select the compartment where you installed the **Compute instance** in the drop down box on the left hand side of the OCI Console.

    * Navigate to the **Compute Instances** page by clicking on the link on the home page of the OCI Console or opening the main menu using the "hamburger" icon ( {{% icon icon="fa-solid fa-bars" %}} )  in the top left corner of the console and searching for
     "instance":

      ![Instances](../images/cleanup-free-tier-2.png " ")

    * Click on the **compute instance name**. The name of your instance will be different than the example below.

      ![Select Compute Instance](../images/cleanup-free-tier-3.png " ")

    * Click on the **Terminate** button.

    * In the Terminate Instance dialog box it is **VERY** important that you select *Permanently delete the attached boot volume*.

      ![Terminate Instance](../images/cleanup-free-tier-4.png " ")

      The instance will now be terminated. This process will take a few minutes. When the status of the instance changes to **terminated** you can move on to the next step.

1. Delete the Custom Image.

    * Select the compartment where you created the **Custom image** in the drop down box on the left hand side of the OCI Console.

    * Navigate to the **Custom Instances** page by opening the main menu using the "hamburger" icon ( {{% icon icon="fa-solid fa-bars" %}} )  in the top left corner of the console and searching for "image":

      ![Custom Image](../images/cleanup-free-tier-1.png " ")

    * Clock in the **three little dots** on the right hand side of table and select **Delete**. And confirm by clicking the **Delete** button in the dialog box.

      ![Custom Image Delete](../images/cleanup-free-tier-5.png " ")

      The custom image you created is now deleted.

1. Delete the Virtual Cloud Network.

    * Select the compartment where you installed the **Compute instance** in the drop down box on the left hand side of the OCI Console.

    * Navigate to the **Virtual cloud networks** page by clicking on the link on the home page of the OCI Console or opening the main menu using the "hamburger" icon ( {{% icon icon="fa-solid fa-bars" %}} )  in the top left corner of the console and searching for
     "instance":

      ![Virtual Cloud Network](../images/cleanup-free-tier-6.png " ")

    * Click on the **network** name.

      ![Virtual Cloud Network Name](../images/cleanup-free-tier-7.png " ")

    * Click on the **Delete** button.

    * In the **Delete Virtual Cloud Network** dialog box, it is **important** that you select **Specific Compartment** and the compartment where you installed the VCN. Otherwise the scan will can all the compartments in the tenancy. Click on the **Scan** button.

      ![Virtual Cloud Network Name](../images/cleanup-free-tier-8.png " ")

    * When the scan is complete, click on the **Delete All** button. Click the **Close** button when the deletion is complete.

      The VCN you created is now deleted.
