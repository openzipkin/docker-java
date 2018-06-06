FROM openjdk:8-jre-alpine
MAINTAINER OpenZipkin "http://zipkin.io/"

# Setup curl for convenience as all derivative images use it, and putting
# it in one layer (via squash) is helpful
RUN apk add --update --no-cache curl

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf