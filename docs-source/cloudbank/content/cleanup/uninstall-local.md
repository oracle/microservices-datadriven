+++
archetype = "page"
title = "Local cleanup"
weight = 2
+++

> **Note:** These steps apply only if you chose the option to install in a local container.



1. Stop the local container using this command:

   ```bash
   docker stop obaas
   ```

   > **Note:** If you want to use the environment again later, stop at this step.  You can restart it later with the command `docker start obaas`.

1. Remove the local container using this command:

   ```bash
   docker rm obaas
   ```

