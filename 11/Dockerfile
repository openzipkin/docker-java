FROM azul/zulu-openjdk-debian:11 AS jre

# Needed for --strip-debug
RUN apt-get -y update && apt-get -y install binutils

# Included modules cherrypicked from https://docs.oracle.com/en/java/javase/11/docs/api/
#
# jdk.unsupported is undocumented but contains Unsafe, which is used by several dependencies to
# improve performance.
RUN cd / && jlink --no-header-files --no-man-pages --compress=0 --strip-debug \
    --add-modules java.base,java.desktop,java.instrument,java.logging,java.management,java.management.rmi,java.sql,\
java.sql.rowset,java.naming,jdk.naming.dns,jdk.unsupported \
    --output jre

# We extract JRE's hard dependencies, libz and SSL certs, from the fat JRE image.
FROM gcr.io/distroless/java:11-debug AS deps

FROM gcr.io/distroless/cc:debug

SHELL ["/busybox/sh", "-c"]

COPY --from=deps /etc/ssl/certs/java /etc/ssl/certs/java

COPY --from=deps /lib/x86_64-linux-gnu/libz.so.1.2.8 /lib/x86_64-linux-gnu/libz.so.1.2.8
RUN ln -s /lib/x86_64-linux-gnu/libz.so.1.2.8 /lib/x86_64-linux-gnu/libz.so.1

COPY --from=jre /jre /usr/lib/jvm/zulu-11-amd64-slim
RUN ln -s /usr/lib/jvm/zulu-11-amd64-slim/bin/java /usr/bin/java

ENTRYPOINT ["/usr/bin/java", "-jar"]
