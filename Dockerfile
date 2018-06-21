FROM openjdk:8-jre-alpine
MAINTAINER OpenZipkin "http://zipkin.io/"

# Add edge repo, needed for tools downstream like runit
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
# Avoid warning: This apk-tools is OLD!
RUN apk add --upgrade --no-cache apk-tools

# Setup curl and bash for convenience as all derivative images use it
RUN apk add --update --no-cache curl bash apk-tools

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# Dependent images all assume bash, so let's set that here
SHELL ["/bin/bash", "-c"]
