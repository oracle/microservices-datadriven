FROM jenkins/jenkins:lts-jdk11

# if we want to install via apt
USER root

# install plugins
RUN jenkins-plugin-cli --plugins blueocean docker-workflow matrix-auth git workflow-aggregator credentials-binding configuration-as-code kubernetes-cli

USER jenkins