# This builds a base JRE 8 image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# Update, but use a stable version so that there's less layer drift during multi-day releases
ARG alpine_version=3.12.1
# Use a quay.io mirror to prevent build outages due to Docker Hub pull quotas
FROM quay.io/app-sre/alpine:$alpine_version as base

ARG maintainer="OpenZipkin https://gitter.im/openzipkin/zipkin"
LABEL maintainer=$maintainer
LABEL org.opencontainers.image.authors=$maintainer
LABEL org.opencontainers.image.description="OpenJDK provided by IcedTea on Alpine Linux"

# OpenJDK Package version from here https://pkgs.alpinelinux.org/packages?name=openjdk8
ARG java_version
ENV JAVA_VERSION=$java_version
ARG java_major_version=8
ENV JAVA_MAJOR_VERSION=$java_major_version

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

WORKDIR /java

ENTRYPOINT ["java", "-jar"]

FROM base as jdk

# Install OS packages that support most software we build
# * openjdk8: includes openjdk8, but not docs or demos
# * tar: BusyBux built-in tar doesn't support --strip=1
# * libc6-compat: BoringSSL for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
RUN PACKAGE=openjdk${JAVA_MAJOR_VERSION} && \
    apk --no-cache add openjdk8=~${JAVA_VERSION} tar libc6-compat && \
    java -version

# Add Maven and invoke help:evaluate to verify the install as this is used in other release scripts
ARG maven_version=3.6.3
RUN APACHE_MIRROR=$(wget -qO- https://www.apache.org/dyn/closer.cgi\?as_json\=1 | sed -n '/preferred/s/.*"\(.*\)"/\1/gp') && \
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
# * libc6-compat: BoringSSL for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
RUN apk add --no-cache openjdk8-jre=~${JAVA_VERSION} libc6-compat && \
    java -version
