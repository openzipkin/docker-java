# This builds a base JDK and JRE 11+ image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# To allow local builds, we default this to 15. Releases should set this to Zulu's most-specific
# Java 15 image tag https://hub.docker.com/r/azul/zulu-openjdk-alpine/tags?page=1&name=15
ARG zulu_tag=15

FROM azul/zulu-openjdk-alpine:$zulu_tag as zuluJDK

WORKDIR /java
# CD into the directory in order to copy paths without symlinks
RUN (cd ${JAVA_HOME} && cp -rp * /java/) && \
    # Remove any symlinks as these won't resolve later
    find . -type l -exec rm -f {} \;

FROM alpine:3.12 as base

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

ENTRYPOINT ["/usr/bin/java", "-jar"]

FROM base as jdk

COPY --from=zuluJDK /java/ .
RUN ln -s ${PWD}/bin/java /usr/bin/java && \
    ln -s ${PWD}/bin/jar /usr/bin/jar

# * binutils is needed for some node modules and jlink --strip-debug
# * BusyBux built-in tar doesn't support --strip=1
# * Maven doesn't need an installer
ARG maven_version=3.6.3
RUN apk add --no-cache binutils tar && \
    APACHE_MIRROR=$(wget -qO- https://www.apache.org/dyn/closer.cgi\?as_json\=1 | sed -n '/preferred/s/.*"\(.*\)"/\1/gp') && \
    MAVEN_DIST_URL=$APACHE_MIRROR/maven/maven-3/$maven_version/binaries/apache-maven-$maven_version-bin.tar.gz && \
    mkdir maven && wget -qO- $MAVEN_DIST_URL | tar xz --strip=1 -C maven && \
    ln -s ${PWD}/maven/bin/mvn /usr/bin/mvn

# Use a temporary target to build a JRE using the JDK we just built
FROM jdk as install

WORKDIR /install

# Included modules cherry-picked from https://docs.oracle.com/en/java/javase/15/docs/api/
RUN ${JAVA_HOME}/bin/jlink --no-header-files --no-man-pages --compress=0 --strip-debug --add-modules \
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

# Our JRE image is minimal: Only Alpine, libc6-compat and a stripped down JRE
FROM base as jre

COPY --from=install /install/jre ${JAVA_HOME}
RUN ln -s ${JAVA_HOME}/bin/java /usr/bin/java
