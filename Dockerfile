# This builds a base JRE 8 image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# alpine_version is the base layer of full and jre image
#
# Use latest version here: https://github.com/orgs/openzipkin/packages/container/package/alpine
ARG alpine_version=3.12.1
FROM ghcr.io/openzipkin/alpine:$alpine_version as base

# java_version is hard-coded here to allow the following to work:
#  * `docker build https://github.com/openzipkin/docker-java.git`
#
# When updating, also update the README
#  * Use current version from https://pkgs.alpinelinux.org/packages?name=openjdk18
ARG java_version=8.272.10
ENV JAVA_VERSION=$java_version
LABEL java-version=$java_version

ARG java_major_version=8
ENV JAVA_MAJOR_VERSION=$java_major_version
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
# Prefix Alpine Linux default path with ${JAVA_HOME}/bin
ENV PATH=${JAVA_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /java

ENTRYPOINT ["java", "-jar"]

# The JDK image includes a few build utilities and Maven
FROM base as jdk
LABEL org.opencontainers.image.description="OpenJDK on Alpine Linux"
ARG maven_version=3.6.3
LABEL maven-version=$maven_version

# RUN, COPY, and ADD instructions create layers. While layer count is less important in modern
# Docker, it doesn't help performance to intentionally make multiple RUN layers in a base image.
RUN \
#
# Install OS packages that support most software we build
# * openjdk8: includes openjdk8, but not docs or demos
# * tar: BusyBux built-in tar doesn't support --strip=1
PACKAGE=openjdk${JAVA_MAJOR_VERSION} && \
apk --no-cache add openjdk8=~${JAVA_VERSION} tar && \
#
# Typically, only amd64 is tested in CI: Run commands that ensure binaries match current arch.
java -version && \
#
# Install Maven by downloading it from and Apache mirror. Prime local repository with common plugins
APACHE_MIRROR=$(wget -qO- https://www.apache.org/dyn/closer.cgi\?as_json\=1 | sed -n '/preferred/s/.*"\(.*\)"/\1/gp') && \
MAVEN_DIST_URL=$APACHE_MIRROR/maven/maven-3/$maven_version/binaries/apache-maven-$maven_version-bin.tar.gz && \
mkdir maven && wget -qO- $MAVEN_DIST_URL | tar xz --strip=1 -C maven && \
ln -s ${PWD}/maven/bin/mvn /usr/bin/mvn && \
mvn -q --batch-mode help:evaluate -Dexpression=maven.version -q -DforceStdout && \
mvn -q --batch-mode org.apache.maven.plugins:maven-dependency-plugin:3.1.2:get -Dmdep.skip

# Our JRE image is minimal: Only Alpine, libc6-compat and a JRE
FROM base as jre
LABEL org.opencontainers.image.description="OpenJDK JRE provided by IcedTea on Alpine Linux"

# Finalize JRE install:
# * openjdk8-jre: only the JRE, not the JDK
RUN apk add --no-cache openjdk8-jre=~${JAVA_VERSION} && \
# Typically, only amd64 is tested in CI: Run a command to ensure binaries match current arch.
java -version
