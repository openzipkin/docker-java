# This builds a base JDK and JRE 8 image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# docker_parent_image is the base layer of full and jre image
#
# Use latest version here: https://github.com/orgs/openzipkin/packages/container/package/alpine
ARG docker_parent_image=ghcr.io/openzipkin/alpine:3.21.2

# We copy files from the context into a scratch container first to avoid a problem where docker and
# docker-compose don't share layer hashes https://github.com/docker/compose/issues/883 normally.
# COPY --from= works around the issue.
FROM scratch AS code

COPY . /code/

FROM $docker_parent_image AS base

# java_version is hard-coded here to allow the following to work:
#  * `docker build https://github.com/openzipkin/docker-java.git`
#
# When updating, also update the README
#  * Use current version from https://pkgs.alpinelinux.org/packages?name=openjdk8
# This is defined in many places because Docker has no "env" script functionality unless you use
# docker-compose: When updating, update everywhere.
ARG java_version=8.432.06
ARG java_home=/usr/lib/jvm/java-1.8-openjdk
LABEL java-version=$java_version
LABEL java-home=$java_home

ENV JAVA_VERSION=$java_version
ENV JAVA_HOME=$java_home
# Prefix Alpine Linux default path with ${JAVA_HOME}/bin
ENV PATH=${JAVA_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /java

ENTRYPOINT ["java", "-jar"]

# The JDK image includes a few build utilities and Maven
FROM base AS jdk
LABEL org.opencontainers.image.description="OpenJDK on Alpine Linux"
ARG java_version=8.432.06
ARG maven_version=3.9.9
LABEL maven-version=$maven_version

COPY --from=code /code/install.sh .
RUN ./install.sh $java_version $maven_version && rm install.sh

# Our JRE image is minimal: Only Alpine, libc6-compat and a JRE
FROM base AS jre
LABEL org.opencontainers.image.description="OpenJDK JRE provided by IcedTea on Alpine Linux"

# Finalize JRE install:
# * openjdk8-jre: only the JRE, not the JDK
RUN apk add --no-cache openjdk8-jre=~${JAVA_VERSION} && \
# Typically, only amd64 is tested in CI: Run a command to ensure binaries match current arch.
java -version
