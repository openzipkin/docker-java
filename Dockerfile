# This is a base JRE image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

FROM alpine:3.12 as install

WORKDIR /install

# Install latest JDK 15: we will later use jlink to create a smaller JRE than the default (200MB)
RUN wget --quiet https://cdn.azul.com/public_keys/alpine-signing@azul.com-5d5dc44c.rsa.pub -P /etc/apk/keys/
RUN echo https://repos.azul.com/zulu/alpine >> /etc/apk/repositories
#   binutils is needed for --strip-debug
RUN apk add --no-cache zulu15-jdk binutils

# Included modules cherrypicked from https://docs.oracle.com/en/java/javase/11/docs/api/
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

FROM alpine:3.12

MAINTAINER OpenZipkin "http://zipkin.io/"

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# Setup the JAVA_HOME and ensure it is in the PATH
COPY --from=install /install/jre /jre
ENV JAVA_HOME=/jre
RUN ln -s ${JAVA_HOME}/bin/java /usr/bin/java

ENTRYPOINT ["/usr/bin/java", "-jar"]
