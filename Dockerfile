# This builds a base JDK 7 image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# java_version is hard-coded here to allow the following to work:
#  * `docker build https://github.com/openzipkin/docker-java.git`
#
# When updating, also update the README
#  * Use current version from https://hub.docker.com/r/azul/zulu-openjdk-alpine/tags?page=1&name=6u
# This is defined in many places because Docker has no "env" script functionality unless you use
# docker-compose: When updating, update everywhere.
ARG java_version=6u119
FROM azul/zulu-openjdk-alpine:${java_version}
ARG maintainer="OpenZipkin https://gitter.im/openzipkin/zipkin"
LABEL maintainer=$maintainer
LABEL org.opencontainers.image.authors=$maintainer
LABEL org.opencontainers.image.description="Zulu on Alpine Linux"
LABEL java-version=$java_version

ENV JAVA_VERSION=$java_version
# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
# Typically, only amd64 is tested in CI: Run a command to ensure binaries match current arch.
java -version

WORKDIR /java

ENTRYPOINT ["java", "-jar"]
