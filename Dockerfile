# This builds a base JRE 8 image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# Update, but use a stable version so that there's less layer drift during multi-day releases
ARG alpine_version=3.12.1
FROM alpine:$alpine_version as jre

ARG maintainer="OpenZipkin https://gitter.im/openzipkin/zipkin"
LABEL maintainer=$maintainer
LABEL org.opencontainers.image.authors=$maintainer
LABEL org.opencontainers.image.description="OpenJDK on Alpine Linux"

# OpenJDK Package version from here https://pkgs.alpinelinux.org/packages?name=openjdk8
ARG java_version
ENV JAVA_VERSION=$java_version

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
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

# Install OS packages that support most software we build
# * libc6-compat: BoringSSL for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
RUN PACKAGE=openjdk$(echo ${JAVA_VERSION}| cut -f1 -d.)-jre && \
    # Allow boringssl for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
    apk --no-cache add ${PACKAGE}=~${JAVA_VERSION} libc6-compat && \
    java -version

WORKDIR /java

ENTRYPOINT ["java", "-jar"]
