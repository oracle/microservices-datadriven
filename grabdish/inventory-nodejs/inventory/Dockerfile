# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

FROM oraclelinux:7-slim

ARG release=19
ARG update=5

RUN  yum -y install oracle-release-el7 oracle-nodejs-release-el7 && \
     yum-config-manager --disable ol7_developer_EPEL && \
     yum -y install oracle-instantclient${release}.${update}-basiclite nodejs && \
     rm -rf /var/cache/yum

# Create app directory
WORKDIR /app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./

RUN npm install
RUN npm install oci-common
RUN npm install oci-secrets
RUN npm install oci-vault
# If you are building your code for production
# RUN npm ci --only=production

# Bundle app source
COPY . .

EXPOSE 8080
CMD [ "node", "app.js" ]
