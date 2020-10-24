# This builds a base JRE 8 image that also includes a working shell
#
# You can choose to lint this via the following command:
# docker run --rm -i hadolint/hadolint < Dockerfile

# To allow local builds, we default this to 7u282. Releases should set this to Zulu's most-specific
# Java 7u282 image tag https://hub.docker.com/r/azul/zulu-openjdk-alpine/tags?page=1&name=7u282
ARG zulu_tag=7u282

FROM azul/zulu-openjdk-alpine:$zulu_tag as zuluJDK

LABEL MAINTAINER OpenZipkin "http://zipkin.io/"

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

WORKDIR ${JAVA_HOME}

ENTRYPOINT ["java", "-jar"]
