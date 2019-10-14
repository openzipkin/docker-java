FROM azul/zulu-openjdk-debian:11 AS jre

RUN apt-get -y update && apt-get -y install binutils

RUN cd / && jlink --no-header-files --no-man-pages --compress=2 --strip-debug \
    --add-modules $(java --list-modules | awk -F"@" -vORS=, '{ print $1 }' | sed 's/,$/\n/') \
    --output jre

FROM gcr.io/distroless/java:11-debug AS deps

FROM gcr.io/distroless/cc:debug

SHELL ["/busybox/sh", "-c"]

COPY --from=deps /lib/x86_64-linux-gnu/* /lib/x86_64-linux-gnu/
COPY --from=deps /usr/lib/x86_64-linux-gnu/* /usr/lib/x86_64-linux-gnu/

COPY --from=jre /jre /usr/lib/jvm/zulu-11-amd64
RUN ln -s /usr/lib/jvm/zulu-11-amd64/bin/java /usr/bin/java

ENTRYPOINT ["/usr/bin/java", "-jar"]
