# This builds a base JDK and JRE image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile
FROM alpine:3.12 as base

ARG java_release=8

LABEL MAINTAINER OpenZipkin "http://zipkin.io/"

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# Save Java release argument so it can be seen by other layers
ENV JAVA_RELEASE $java_release

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# Add edge repo, needed for latest JRE and tools downstream like runit
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

ENTRYPOINT ["/usr/bin/java", "-jar"]

FROM base as jdk

# Update JDK to latest patch
RUN apk add --upgrade --no-cache openjdk$JAVA_RELEASE

FROM base as jre

# Update JRE to latest patch
RUN apk add --upgrade --no-cache openjdk$JAVA_RELEASE-jre
