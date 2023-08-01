[![Gitter chat](http://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg)](https://gitter.im/openzipkin/zipkin)
[![Build Status](https://github.com/openzipkin/docker-java/workflows/test/badge.svg)](https://github.com/openzipkin/docker-java/actions?query=workflow%3Atest)

`ghcr.io/openzipkin/java` is a minimal OpenJDK [Alpine Linux](https://github.com/openzipkin/docker-alpine) image.

GitHub Container Registry: [ghcr.io/openzipkin/java](https://github.com/orgs/openzipkin/packages/container/package/java) includes:
 * `master` tag: latest commit
 * `MAJOR.MINOR.PATCH` tag: release corresponding to a [Current OpenJDK Version](https://pkgs.alpinelinux.org/packages?name=openjdk15)

Tags ending in `-jre` include only a JRE where unqualified tags include the full JDK, Maven, and a
few build utilities.

## Using this image
This is an internal base layer primarily used in [zipkin](https://github.com/openzipkin/zipkin).

To try the image, run the `java -version` command:
```bash
docker run --rm ghcr.io/openzipkin/java:17.0.8_p7 -version
openjdk version "17.0.5" 2022-10-18
OpenJDK Runtime Environment (build 17.0.5+8-alpine-r2)
OpenJDK 64-Bit Server VM (build 17.0.5+8-alpine-r2, mixed mode, sharing)
```

## Release process
Build the `Dockerfile` using the current version without the revision classifier from here:
 * https://pkgs.alpinelinux.org/packages?name=openjdk15
```bash
# Note 17.0.8_p7 not 17.0.8_p7-r0!
./build-bin/build 17.0.8_p7
```

Next, verify the built image matches that version:
```bash
docker run --rm openzipkin/java:test -version
openjdk version "17.0.5" 2022-10-18
OpenJDK Runtime Environment (build 17.0.5+8-alpine-r2)
OpenJDK 64-Bit Server VM (build 17.0.5+8-alpine-r2, mixed mode, sharing)
```

To release the image, push a tag matching the arg to `build-bin/build` (ex `17.0.8_p7`).
This triggers a [GitHub Actions](https://github.com/openzipkin/docker-java/actions) job to push the image.
