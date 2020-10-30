# This builds a base JDK and JRE 11+ image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# Update, but use a stable version so that there's less layer drift during multi-day releases
ARG alpine_version=3.12.1
FROM alpine:$alpine_version as openJDK

# OpenJDK Package version from here https://pkgs.alpinelinux.org/packages?name=openjdk15
ARG java_version
ENV JAVA_VERSION=$java_version

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    echo http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
    PACKAGE=openjdk$(echo ${JAVA_VERSION}| cut -f1 -d.) && \
    apk --no-cache add ${PACKAGE}=~${JAVA_VERSION} && \
    java -version java_version

ENV JAVA_HOME=/usr/lib/jvm/default-jvm/

WORKDIR /java

# CD into the directory in order to copy paths without symlinks
RUN (cd ${JAVA_HOME} && cp -rp * /java/) && \
    # Remove any symlinks as these won't resolve later
    find . -type l -exec rm -f {} \;

FROM alpine:$alpine_version as base

LABEL maintainer="OpenZipkin https://zipkin.io/"

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV JAVA_HOME=/java

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

WORKDIR ${JAVA_HOME}

# Allow boringssl for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
RUN apk add --no-cache java-cacerts libc6-compat && \
    mkdir -p lib/security/ && ln -s /etc/ssl/certs/java/cacerts ${PWD}/lib/security/cacerts

ENTRYPOINT ["/usr/bin/java", "-jar"]

FROM base as jdk

COPY --from=openJDK /java/ .
RUN ln -s ${PWD}/bin/java /usr/bin/java && \
    ln -s ${PWD}/bin/jar /usr/bin/jar

# Later installations may require more recent versions of packages such as nodejs
RUN for repository in main testing community; do \
      repository_url=https://dl-cdn.alpinelinux.org/alpine/edge/${repository} && \
      grep -qF -- $repository_url /etc/apk/repositories || echo $repository_url >> /etc/apk/repositories; \
    done

# * binutils is needed for some node modules and jlink --strip-debug
# * BusyBux built-in tar doesn't support --strip=1
# * Maven doesn't need an installer
ARG maven_version=3.6.3
RUN apk add --no-cache binutils tar && \
    APACHE_MIRROR=$(wget -qO- https://www.apache.org/dyn/closer.cgi\?as_json\=1 | sed -n '/preferred/s/.*"\(.*\)"/\1/gp') && \
    MAVEN_DIST_URL=$APACHE_MIRROR/maven/maven-3/$maven_version/binaries/apache-maven-$maven_version-bin.tar.gz && \
    mkdir maven && wget -qO- $MAVEN_DIST_URL | tar xz --strip=1 -C maven && \
    ln -s ${PWD}/maven/bin/mvn /usr/bin/mvn && \
    # use help:evalate to verify the install as this is used in other release scripts (and will seed some plugins)
    mvn help:evaluate -Dexpression=maven.version -q -DforceStdout

# Use a temporary target to build a JRE using the JDK we just built
FROM jdk as install

WORKDIR /install

RUN JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2| cut -f1 -d.) && \
# Opt out of --strip-debug when openjdk15+arm64 per https://github.com/openzipkin/docker-java/issues/34
if [[ "${JAVA_VERSION}" = "15" && "$(uname -m)" = "aarch64" ]]; then STRIP=""; else STRIP="--strip-debug"; fi && \
# Included modules cherry-picked from https://docs.oracle.com/en/java/javase/15/docs/api/
${JAVA_HOME}/bin/jlink --vm=server --no-header-files --no-man-pages --compress=0 ${STRIP} --add-modules \
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

COPY --from=install /install/jre ${JAVA_HOME}
RUN ln -s ${JAVA_HOME}/bin/java /usr/bin/java
