# This builds a base JDK and JRE 11+ image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# Update, but use a stable version so that there's less layer drift during multi-day releases
ARG alpine_version=3.12.1
FROM alpine:$alpine_version as base

ARG maintainer="OpenZipkin https://gitter.im/openzipkin/zipkin"
LABEL maintainer=$maintainer
LABEL org.opencontainers.image.authors=$maintainer
LABEL org.opencontainers.image.description="OpenJDK on Alpine Linux"

# OpenJDK Package version from here https://pkgs.alpinelinux.org/packages?name=openjdk15
ARG java_version
ENV JAVA_VERSION=$java_version
ARG java_major_version=15
ENV JAVA_MAJOR_VERSION=$java_major_version

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-openjdk
# Prefix Alpine Linux default path with ${JAVA_HOME}/bin
ENV PATH=${JAVA_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# Later installations may require more recent versions of packages such as nodejs
RUN for repository in main testing community; do \
      repository_url=https://dl-cdn.alpinelinux.org/alpine/edge/${repository} && \
      grep -qF -- $repository_url /etc/apk/repositories || echo $repository_url >> /etc/apk/repositories; \
    done

WORKDIR /java

ENTRYPOINT ["java", "-jar"]

FROM base as jdk

# Install OS packages that support most software we build
# * openjdk15-jdk: smaller than openjdk15, which includes docs and demos
# * openjdk15-jmods: needed for module support
# * binutils: needed for some node modules and jlink --strip-debug
# * tar: BusyBux built-in tar doesn't support --strip=1
# * libc6-compat: BoringSSL for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
RUN PACKAGE=openjdk${JAVA_MAJOR_VERSION} && \
    apk --no-cache add ${PACKAGE}-jmods=~${JAVA_VERSION} ${PACKAGE}-jdk=~${JAVA_VERSION} binutils tar libc6-compat && \
    java -version && jar --version && jlink --version

# Add Maven and invoke help:evaluate to verify the install as this is used in other release scripts
ARG maven_version=3.6.3
RUN APACHE_MIRROR=$(wget -qO- https://www.apache.org/dyn/closer.cgi\?as_json\=1 | sed -n '/preferred/s/.*"\(.*\)"/\1/gp') && \
    MAVEN_DIST_URL=$APACHE_MIRROR/maven/maven-3/$maven_version/binaries/apache-maven-$maven_version-bin.tar.gz && \
    mkdir maven && wget -qO- $MAVEN_DIST_URL | tar xz --strip=1 -C maven && \
    ln -s ${PWD}/maven/bin/mvn /usr/bin/mvn && \
    mvn -q --batch-mode help:evaluate -Dexpression=maven.version -q -DforceStdout && \
    mvn -q --batch-mode org.apache.maven.plugins:maven-dependency-plugin:3.1.2:get -Dmdep.skip

# Use a temporary target to build a JRE using the JDK we just built
FROM jdk as install

WORKDIR /install

# Opt out of --strip-debug when openjdk15+arm64 per https://github.com/openzipkin/docker-java/issues/34
# This is because we cannot set the following in jlink -Djdk.lang.Process.launchMechanism=vfork
RUN if [[ "${JAVA_MAJOR_VERSION}" = "15" && "$(uname -m)" = "aarch64" ]]; then STRIP=""; else STRIP="--strip-debug"; fi && \
# Included modules cherry-picked from https://docs.oracle.com/en/java/javase/15/docs/api/
jlink --vm=server --no-header-files --no-man-pages --compress=0 ${STRIP} --add-modules \
java.base,java.logging,\
# java.desktop includes java.beans which is used by Spring
java.desktop,\
# our default server includes SQL
java.sql,\
# instrumentation
java.instrument,\
# remote debug
jdk.jdwp.agent,\
# JVM metrics such as garbage collection
jdk.management,\
# Prevents us from needing a different base layer for kafka-zookeeper
# non-Netty based DNS
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

LABEL org.opencontainers.image.description="Minimal OpenJDK JRE on Alpine Linux"

COPY --from=install /install/jre/ ${JAVA_HOME}/

# Finalize JRE install:
# * java-cacerts: ensures the certificates match what the JDK image contains
# * libc6-compat: BoringSSL for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
RUN apk add --no-cache java-cacerts libc6-compat && \
    java -version
