# This is a base JRE image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# Since Distroless is Debian based, we take an updated JRE from Zulu's Debian image
FROM azul/zulu-openjdk-debian:14 AS jre

# Needed for --strip-debug
RUN apt-get -y update && apt-get --no-install-recommends -y install binutils

# Included modules cherrypicked from https://docs.oracle.com/en/java/javase/11/docs/api/
#
# jdk.unsupported is undocumented but contains Unsafe, which is used by several dependencies to
# improve performance.
WORKDIR /
RUN jlink --no-header-files --no-man-pages --compress=0 --strip-debug \
    --add-modules java.base,java.logging,\
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
# sun.misc.Unsafe and friends
jdk.unsupported,\
# Elasticsearch 7+ crashes without Thai Segmentation support
#  Add <900K instead of a different base layer
jdk.localedata --include-locales en,th\
 --output jre

# We extract JRE's hard dependencies, libz and SSL certs, from the fat JRE image.
#   See https://console.cloud.google.com/gcr/images/distroless/GLOBAL/java
FROM gcr.io/distroless/java:11-debug AS deps

# Mainly, this gets BusyBox
#   See https://console.cloud.google.com/gcr/images/distroless/GLOBAL/cc
FROM gcr.io/distroless/cc:debug

LABEL MAINTAINER Zipkin "https://zipkin.io/"

# Similar to Alpine Linux, we ensure /bin/sh works (via BusyBox)
RUN ["/busybox/sh", "-c", "ln -s /busybox/sh /bin/sh"]

COPY --from=deps /etc/ssl/certs/java /etc/ssl/certs/java
COPY --from=deps /lib/x86_64-linux-gnu/libz.so.1.2.8 /lib/x86_64-linux-gnu/libz.so.1.2.8
RUN ln -s /lib/x86_64-linux-gnu/libz.so.1.2.8 /lib/x86_64-linux-gnu/libz.so.1

COPY --from=jre /jre /jre

# Zulu installs the JRE under /jre. Setup the JAVA_HOME and ensure it is in the PATH
ENV JAVA_HOME=/jre
RUN ln -s ${JAVA_HOME}/bin/java /usr/bin/java

ENTRYPOINT ["/usr/bin/java", "-jar"]
