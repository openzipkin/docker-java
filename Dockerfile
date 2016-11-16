FROM cantara/alpine-zulu-jdk8
MAINTAINER OpenZipkin "http://zipkin.io/"

# Remove 40M worth of SDK things, but link back /usr/local/java/bin to help tools
# that auto-detect JAVA_HOME.
RUN rm -rf /usr/local/java/bin /usr/local/java/lib /usr/local/java/include
# Having the rm and the ln in the same FS layer confuses docker squash
RUN ln -s /usr/local/java/jre/bin /usr/local/java/bin

# Setup curl for convenience as all derivative images use it, and putting
# it in one layer (via squash) is helpful
RUN apk add --update --no-cache curl

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf
