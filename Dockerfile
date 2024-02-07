# This builds a base JDK and JRE 11+ image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# docker_parent_image is the base layer of full and jre image
#
# Use latest version here: https://github.com/orgs/openzipkin/packages/container/package/alpine
ARG docker_parent_image=ghcr.io/openzipkin/alpine:3.19.1

# java_version and java_home are hard-coded here to allow the following:
#  * `docker build https://github.com/openzipkin/docker-java.git`
#
# These are overridden via build-bin/docker/docker_args, ensuring the two are
# coherent (e.g. java 21.* has a java_home of java-21-openjdk).
#
# When updating, also update the README
#  * Use current version from https://pkgs.alpinelinux.org/packages?name=openjdk21, stripping
#    the `-rX` at the end.
ARG java_version=21.0.2_p13
ARG java_home=/usr/lib/jvm/java-21-openjdk

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
#  * Use current version from https://pkgs.alpinelinux.org/packages?name=openjdk21
# This is defined in many places because Docker has no "env" script functionality unless you use
# docker-compose: When updating, update everywhere.
ARG java_version
ARG java_home
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
ARG maven_version=3.9.6
LABEL maven-version=$maven_version

COPY --from=code /code/install.sh .
RUN ./install.sh $java_version $maven_version && rm install.sh

# Use a temporary target to build a JRE using the JDK we just built
FROM jdk as install

WORKDIR /install

# Included modules cherry-picked from https://docs.oracle.com/en/java/javase/21/docs/api/
#
# Note: Only include modules needed for the openzipkin/zipkin and
# openzipkin/zipkin-slim images. It is fine for test images to use a full JRE.
RUN jlink --vm=server --no-header-files --no-man-pages --compress=0 --strip-debug --add-modules \
java.base,java.logging,\
# java.desktop includes java.beans which is used by Spring
java.desktop,\
# our default server includes SQL
java.sql,\
# MariaDB Connector/J 3.x additionally requires rowset
java.sql.rowset,\
# instrumentation
java.instrument,\
# remote debug
jdk.jdwp.agent,\
# JVM metrics such as garbage collection
jdk.management,\
# TLS handshake with servers that use elliptic curve certificates
jdk.crypto.ec,\
# jdk.unsupported is undocumented but contains Unsafe, which is used by several dependencies to
# improve performance. Ex. sun.misc.Unsafe and friends
jdk.unsupported,\
jdk.localedata --include-locales en \
--output jre

# Our JRE image is minimal: Only Alpine, gcompat and a stripped down JRE
FROM base as jre
LABEL org.opencontainers.image.description="Minimal OpenJDK JRE on Alpine Linux"

COPY --from=install /install/jre/ ${JAVA_HOME}/

# Typically, only amd64 is tested in CI: Run a command to ensure binaries match current arch.
RUN java -version
