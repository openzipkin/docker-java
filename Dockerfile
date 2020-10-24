# This builds a base JRE 8 image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# To allow local builds, we default this to 8-jre-headless. Releases should set this to Zulu's most-specific
# Java 8-jre-headless image tag https://hub.docker.com/r/azul/zulu-openjdk-alpine/tags?page=1&name=8-jre-headless
ARG zulu_tag=8-jre-headless

FROM azul/zulu-openjdk-alpine:$zulu_tag as zuluJDK

WORKDIR /java
# CD into the directory in order to copy paths without symlinks
RUN (cd ${JAVA_HOME} && cp -rp * /java/) && \
    # Remove any symlinks as these won't resolve later
    find . -type l -exec rm -f {} \;

FROM alpine:3.12

LABEL MAINTAINER OpenZipkin "http://zipkin.io/"

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# Allow boringssl for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
RUN apk add --no-cache libc6-compat

ENV JAVA_HOME=/java
WORKDIR ${JAVA_HOME}

# Copy the JDK from Zulu's JRE image
COPY --from=zuluJDK /java/jre/ .
RUN ln -s ${PWD}/bin/java /usr/bin/java

ENTRYPOINT ["/usr/bin/java", "-jar"]
