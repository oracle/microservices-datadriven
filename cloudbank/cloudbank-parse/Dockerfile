############################################################
# Build stage
############################################################
FROM node:lts-alpine as build

RUN apk update; \
  apk add git;
WORKDIR /tmp

# Copy package.json first to benefit from layer caching
COPY package*.json ./

# Copy src to have config files for install
COPY . .

# Clean npm cache; added to fix an issue with the install process
RUN npm cache clean --force

# Install all dependencies
RUN npm ci

# Run build steps
RUN npm run build

############################################################
# Release stage
############################################################
FROM node:lts-alpine as release

RUN apk update; \
  apk add git;

VOLUME /parse-server/cloud /parse-server/config

WORKDIR /parse-server

COPY package*.json ./

# Clean npm cache; added to fix an issue with the install process
RUN npm cache clean --force
RUN npm ci --production --ignore-scripts

COPY bin bin
COPY public_html public_html
COPY views views
  
# Where the server side cloud functions are kept
COPY cloud cloud
# COPY lib lib   // For Debug Builds
COPY --from=build /tmp/lib lib
RUN mkdir -p logs && chown -R node: logs

ENV PORT=1337
ENV VERBOSE=true
ENV PARSE_SERVER_APPLICATION_ID=APPLICATION_ID
ENV PARSE_SERVER_MASTER_KEY=MASTER_KEY
#  Location of Cloud Functions
ENV PARSE_SERVER_CLOUD=./cloud/main.js
# Oracle Mongo API Connection String
# ENV PARSE_SERVER_DATABASE_URI=mongodb://admin:password@DBConnectionString:Port/admin?authMechanism=PLAIN\&authSource=\$external\&ssl=true\&retryWrites=false
USER node
EXPOSE $PORT

ENTRYPOINT ["node", "./bin/parse-server"]
