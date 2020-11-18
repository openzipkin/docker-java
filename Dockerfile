# This builds a base JDK and JRE 11+ image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# alpine_version is the base layer of full and jre image
#
# Use latest version here: https://github.com/orgs/openzipkin/packages/container/package/alpine
ARG alpine_version=3.12.1
FROM ghcr.io/openzipkin/alpine:$alpine_version as base
LABEL org.opencontainers.image.description="OpenJDK on Alpine Linux"

# OpenJDK Package version from here https://pkgs.alpinelinux.org/packages?name=openjdk15
ARG java_version=15.0.1_p9
ENV JAVA_VERSION=$java_version
LABEL java-version=$java_version

ARG java_major_version=15
ENV JAVA_MAJOR_VERSION=$java_major_version
ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-openjdk
# Prefix Alpine Linux default path with ${JAVA_HOME}/bin
ENV PATH=${JAVA_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

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
    apk --no-cache add ${PACKAGE}-jmods=~${JAVA_VERSION} ${PACKAGE}-jdk=~${JAVA_VERSION} binutils tar && \
    java -version && jar --version && jlink --version

# Add Maven and invoke help:evaluate to verify the install as this is used in other release scripts
ARG maven_version=3.6.3
LABEL maven-version=$maven_version
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
