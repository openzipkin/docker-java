# This is a base JRE image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# Zulu's most-specific tag of the 15 image https://hub.docker.com/r/azul/zulu-openjdk-alpine/tags?page=1&name=15
ARG zulu_tag

FROM azul/zulu-openjdk-alpine:$zulu_tag as jdk
LABEL MAINTAINER Zipkin "https://zipkin.io/"

# Install Maven, tar and libc hooks
COPY install.sh /tmp/
RUN /tmp/install.sh && rm /tmp/install.sh

FROM jdk as install

WORKDIR /install

# binutils is needed for --strip-debug
RUN apk add --no-cache binutils

# Included modules cherrypicked from https://docs.oracle.com/en/java/javase/15/docs/api/
RUN /usr/lib/jvm/zulu15-ca/bin/jlink --no-header-files --no-man-pages --compress=0 --strip-debug --add-modules \
java.base,java.logging,\
# java.desktop includes java.beans which is used by Spring
java.desktop,\
# our default server includes SQL
java.sql,\
# instrumentation
java.instrument,\
# we don't use JMX, but log4j2 errors without it: LOG4J2-716
java.management,\
# remote debug
jdk.jdwp.agent,\
# JVM metrics such as garbage collection
jdk.management,\
# prevents us from needing a different base layer for kafka-zookeeper
# ZooKeeper needs jdk.management.agent, and adding it is 900K vs 200M for a different base layer
jdk.management.agent,\
# non-netty based DNS
java.naming,jdk.naming.dns,\
# TLS handehake with servers that use elliptic curve certificates
jdk.crypto.ec,\
# jdk.unsupported is undocumented but contains Unsafe, which is used by several dependencies to
# improve performance. Ex. sun.misc.Unsafe and friends
jdk.unsupported,\
# Elasticsearch 7+ crashes without Thai Segmentation support
#  Add <900K instead of a different base layer
jdk.localedata --include-locales en,th\
 --output jre

FROM alpine:3.12 as jre

MAINTAINER OpenZipkin "http://zipkin.io/"

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# Allow boringssl for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
RUN apk add --no-cache libc6-compat

COPY --from=jdk /etc/nsswitch.conf /etc/nsswitch.conf

# Setup the JAVA_HOME and ensure it is in the PATH (use same path as JDK)
ENV JAVA_HOME=/usr/lib/jvm/zulu15-ca
COPY --from=install /install/jre $JAVA_HOME
RUN ln -s ${JAVA_HOME}/bin/java /usr/bin/java

ENTRYPOINT ["/usr/bin/java", "-jar"]
