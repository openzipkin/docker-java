# This builds a base JDK and JRE 11+ image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# docker_parent_image is the base layer of full and jre image
#
# Use latest version here: https://github.com/orgs/openzipkin/packages/container/package/alpine
ARG docker_parent_image=ghcr.io/openzipkin/alpine:3.18.0

# java_version is hard-coded here to allow the following to work:
#  * `docker build https://github.com/openzipkin/docker-java.git`
#
# When updating, also update the README
#  * Use current version from https://pkgs.alpinelinux.org/packages?name=openjdk17, stripping
#    the `-rX` at the end.
ARG java_version=17.0.7_p7

# We copy files from the context into a scratch container first to avoid a problem where docker and
# docker-compose don't share layer hashes https://github.com/docker/compose/issues/883 normally.
# COPY --from= works around the issue.
FROM scratch as code

COPY . /code/

FROM $docker_parent_image as base

# java_version is hard-coded here to allow the following to work:
#  * `docker build https://github.com/openzipkin/docker-java.git`
#
# When updating, also update the README
#  * Use current version from https://pkgs.alpinelinux.org/packages?name=openjdk15
# This is defined in many places because Docker has no "env" script functionality unless you use
# docker-compose: When updating, update everywhere.
ARG java_version
ARG java_home=/usr/lib/jvm/java-17-openjdk
LABEL java-version=$java_version
LABEL java-home=$java_home

ENV JAVA_VERSION=$java_version
ENV JAVA_HOME=$java_home
# Prefix Alpine Linux default path with ${JAVA_HOME}/bin
ENV PATH=${JAVA_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /java

ENTRYPOINT ["java", "-jar"]

# The JDK image includes a few build utilities and Maven
FROM base as jdk
LABEL org.opencontainers.image.description="OpenJDK on Alpine Linux"
ARG java_version
ARG maven_version=3.6.3
LABEL maven-version=$maven_version

COPY --from=code /code/install.sh .
RUN ./install.sh $java_version $maven_version && rm install.sh

# Use a temporary target to build a JRE using the JDK we just built
FROM jdk as install

WORKDIR /install

# Opt out of --strip-debug when openjdk15+arm64 per https://github.com/openzipkin/docker-java/issues/34
# This is because we cannot set the following in jlink -Djdk.lang.Process.launchMechanism=vfork
RUN if [ -d "/usr/lib/jvm/java-17-openjdk" ] && uname -m | grep -E 'aarch64|s390x'; then strip=""; else strip="--strip-debug"; fi && \
# Included modules cherry-picked from https://docs.oracle.com/en/java/javase/15/docs/api/
jlink --vm=server --no-header-files --no-man-pages --compress=0 ${strip} --add-modules \
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
jdk.localedata --include-locales en,th \
--output jre

# Our JRE image is minimal: Only Alpine, libc6-compat and a stripped down JRE
FROM base as jre
LABEL org.opencontainers.image.description="Minimal OpenJDK JRE on Alpine Linux"

COPY --from=install /install/jre/ ${JAVA_HOME}/

# Typically, only amd64 is tested in CI: Run a command to ensure binaries match current arch.
RUN java -version
