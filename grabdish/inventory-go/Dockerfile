FROM golang:alpine AS builder
RUN apk update && apk add --no-cache git build-base
WORKDIR /src

# ENV TNS_ADMIN /Users/pparkins/Downloads/Wallet_grabdish4X2
# RUN echo TNS_ADMIN: $TNS_ADMIN

COPY . .
RUN go get -d -v
# ENV TNS_ADMIN /Users/pparkins/Downloads/Wallet_grabdish4X2
# RUN echo TNS_ADMIN: $TNS_ADMIN
RUN go build -o /go/bin/inventory-go

FROM alpine:latest
ENV LD_LIBRARY_PATH=/lib
RUN wget https://download.oracle.com/otn_software/linux/instantclient/193000/instantclient-basic-linux.x64-19.3.0.0.0dbru.zip && \
    unzip instantclient-basic-linux.x64-19.3.0.0.0dbru.zip && \
    cp -r instantclient_19_3/* /lib && \
    rm -rf instantclient-basic-linux.x64-19.3.0.0.0dbru.zip && \
    apk add libaio && \
    apk add libaio libnsl libc6-compat

RUN cd /lib
RUN ln -s /lib64/* /lib
RUN ln -s libnsl.so.2 /usr/lib/libnsl.so.1
RUN ln -s /lib/libc.so.6 /usr/lib/libresolv.so.2

COPY --from=builder /go/bin/inventory-go /usr/lib/inventory-go
ENTRYPOINT ["/usr/lib/inventory-go"]
