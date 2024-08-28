+++
archetype = "page"
title = "Install in OCI Free Tier"
weight = 3
+++

This option allows you to run Oracle Backend for Spring Boot and Microservices in a containerized environment inside a single OCI Compute Instance.  This option is good if you do not have enough free capacity on your local machine to run the environment, and if you do not have or want to use the resources required for a full production-sized deployment.  This option provides an environment with adequate resources for development and testing, but minimizes the resource usage and costs.

   > **Note:** You only need to choose one of the three deployment options - local, OCI Free Tier or OCI Marketplace.

1. Get an Oracle Cloud Free Tier account

   If you do not already have one, you can obtain an Oracle Cloud Free Tier account as follows:

   * Open a browser and navigate to the [Oracle Cloud Free Tier signup page](https://signup.cloud.oracle.com/).
   * Complete the requested details and click on the **Verify email** button.
   * You will receive an email from "Oracle Cloud" with instructions on how to verify your email address.
   * On the **Account Information** page, enter the requested details.
   * When completed, click on the **Start my free trial** button.
   * You will need to wait a few minutes while your account is created and set up.
   * When the set up is completed, you will see the login page. You will also receive an email confirmation.
   * Log in to your new account. You may be asked to configured secure verification.

1. Copy the custom compute image

   * Choose a compartment in the drop down box on the left hand side of the OCI Console.  

     > **Note:** If you use or plan to use this OCI Cloud account for other purposes as well, Oracle recommends creating compartments to simplify management. You can create a compartment by navigating to the Compartments page in the Identity section of OCI Console. You can use the root compartment if you wish, but it is not generally recommended.

   * Navigate to the **Custom Instances** page by opening the main menu using the "hamburger" icon ( {{% icon icon="fa-solid fa-bars" %}} )  in the top left corner of the console and searching for "image":

      ![Custom Instance import](../images/install-free-tier-3.png " ")

   * Click on the **Import image** button.

   * Choose the option to **Import from an Object Storage URL** and provide the following URL in the **Object Storage URL** field:

     ```url
     https://objectstorage.us-ashburn-1.oraclecloud.com/p/oSwRpU_9v5NGzkJ-P0qKzT1ZN-Y9lJZu1aXO_2N-rkGdJs-hKJt10bRk9TxsCceF/n/maacloud/b/cloudbank-public/o/obaas-1.3.0-2
     ```

   * (Important) Under **Image type** choose the **OCI** option.

   * Click on the **Import image** button to start the import.  

      ![Custom Instance import](../images/install-free-tier-7.png " ")

      > **Note:**  that it might take approximately 10 to 15 minutes to complete the import. You can see the progress on the **Custom image details** page that will be displayed.

1. Create a compute instance

   * Choose a compartment in the drop down box on the left hand side of the OCI Console.  

     > **Note:** If you use or plan to use this OCI Cloud account for other purposes as well, Oracle recommends creating compartments to simplify management. You can create a compartment by navigating to the Compartments page in the Identity section of OCI Console. You can use the root compartment if you wish, but it is not generally recommended.

   * Navigate to the **Compute Instances** page by clicking on the link on the home page of the OCI Console or opening the main menu using the "hamburger" icon ( {{% icon icon="fa-solid fa-bars" %}} )  in the top left corner of the console and searching for
     "instance":

      ![Instances](../images/install-free-tier-1.png " ")

   * Create a Compute Instance by clicking on the **Create instance** button.

   * Enter a name for the instance, for example *obaas-instance*.

   * Scroll down to the **Image and shape** section and click on the **Change Image** button to edit the details.

   * In the image source, choose the option for **My ../images** and choose the image the you imported in the previous step.

        > **Note:** The image will not show up until the import is completed.

      ![Custom image selected](../images/install-free-tier-4.png " ")

     Click on the **Select image** button to confirm your choice.

   * Click on the **Change shape** button to choose the shape of your instance.  Oracle recommends 2 OCPUs and 32 GB of memory to run this CloudBank environment.

      ![Shape selected](../images/install-free-tier-6.png " ")

     Click on the **Select shape** button to confirm your choice.

   * Leave the default values in the **Primary VNIC Section**. By doing so a virtual network and subnets will be created for you.

   * In the **SSH Keys** section, make sure you provide SSH keys so you can log into your instance. You may provide an existing public key if you have one, or generate new keys.

   * Click on the **Create** button to create the instance.  The instance and the virtual network will be started, this will take a few moments.  

1. Start Oracle Backend for Spring Boot and Microservices

   * Note the Public IP Address of your newly created instance in the **Instance access** section of the **Instance details** page
     that is displayed.

      ![Shape selected](../images/install-free-tier-8.png " ")

   * Log into the compute instance using SSH, for example:

     ```bash
     ssh -i <path and filename of private key> -L 1443:localhost:443 ubuntu@207.211.186.88 
     ```

     You will need to use the IP address of your instance in this command. Note that the example command also creates a port forward so that you will be able to access various Web UI's from your local machine.

   * You will be asked to confirm the authenticity of your SSH keys, enter `yes`.

   * The environment will start automatically, including a Kubernetes cluster in a container (using k3s), Oracle Backend for Spring Boot and Microservices and an Oracle Database instance inside that cluster. It will take approximately six minutes for all of the containers to reach ready/running state. You can watch the progress using this command:

     ```bash
     watch kubectl get pod -A
     ```

     > **Note:** Should you require access to it, the `kubeconfig` file for your cluster is located at this location:

     ```bash
     /home/ubuntu/obaas/k3s_data/kubeconfig/kubeconfig.yaml
     ```

     When the environment is fully started, the output will appear similar to this:

     ![Completed startup](../images/install-free-tier-2.png " ")

1. Verify access to web user interfaces

   * On your local machine, open a browser and navigate to the [Spring Operations Center](https://localhost:1443/soc).

   * Log in using the pre-defined user `obaas-admin` and password `Welcome-12345`.

    > **Note:** Since this is a development environment with no DNS name, it is configured with self-signed certificates. Your browser will warn you about the connection security.

   * If you are using Chrome, click on the **Advanced** link and then the **Proceed to localhost (unsafe)** link. If you are using a different browser, perform the equivalent actions.

   * The Spring Operations Center main dashboard will appear similar to this:

     ![Spring Operations Center](../images/install-free-tier-5.png " ")
