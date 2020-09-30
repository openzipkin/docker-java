# zipkin-docker-jre rationale

## Why do we use Alpine Linux instead of Distroless?

### We need a working /bin/sh

Alpine Linux includes `/busybox/sh`, linked to `/bin/sh`. This allows us to
customize startup and add HEALTHCHECK instructions. Notably, Alpine linking
`/bin/sh` allows docker-compose to override health checks as necessary. This is
because docker-compose always invokes its health check overrides with
`/bin/sh -c`.

It is possible to layer BusyBox on a distroless image to perform the same, but
Alpine does this by default.

### We want the smallest base image

We are often criticized for the size of our Docker image, as it is an ancillary
part of people's environments. Zipkin's 'slim' build is currently a 26MB jar
file. The bulk of the size left is the JRE. Here's a comparison of size between
a comparible build of the same JRE, one with Distroless (Debian based) and the
other Alpine.

```
openzipkin/jre-full                  alpine              128317d6038e        20 seconds ago      87.1MB
openzipkin/jre-full                  distroless          0717ad881158        3 minutes ago       102MB
```

### We are still smaller adding BoringSSL support

Some applications like gRPC prefer use of BoringSSL over default TLS libraries.
To support `netty-tcnative-boringssl-static` on Distroless, there are no special
instructions. However, for Alpine we need to install `libc6-compat` per [https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty].

While the additional package increases our distribution by 600KB, it is still
almost 15MB smaller than using Distroless.
