#!/bin/bash

# Download CLI
until curl -s -f -o /home/opc/jenkins-cli.jar "${jenkins_endpoint}/jnlpJars/jenkins-cli.jar"
do
  sleep 1
done

# Create Agent with config.xml
cat /home/opc/config.xml | java -jar /home/opc/jenkins-cli.jar -s ${jenkins_endpoint} -auth ${jenkins_user}:"${jenkins_password}" create-node ${jenkins_agent_name}

# Retrieve corresponding Agent secret
SECRET=$(echo 'println jenkins.model.Jenkins.instance.nodesObject.getNode("'${jenkins_agent_name}'")?.computer?.jnlpMac' \
  | java -jar jenkins-cli.jar -s ${jenkins_endpoint} -auth ${jenkins_user}:"${jenkins_password}" groovy =)

# Set environment variables
export JENKINS_SECRET=$SECRET
export JENKINS_URL=${jenkins_endpoint}
export JENKINS_AGENT_NAME=${jenkins_agent_name}

# Build Docker file and Run Agent
while [ ! -f /tmp/cloud-init-complete ];
  do sleep 1;
done;

# Run Container
docker-compose -f /home/opc/agent.yaml up -d