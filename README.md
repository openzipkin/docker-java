`ghcr.io/openzipkin/java` is a minimal Docker image based on the OpenJDK [Alpine Linux](https://hub.docker.com/_/alpine) package.

On GitHub Container Registry: [ghcr.io/openzipkin/java](https://github.com/orgs/openzipkin/packages/container/package/java) there will be two tags
per version. The one ending in `-jre` is a minimal build including modules Zipkin related images
need. The unqualified is a JDK that also includes Maven.

## Release process
The Docker build is driven by `build_image`. The argument to this must be Alpine's most specific
Java 15 version without the revision classifier, ex `15.0.1_p9-r0` -> `15.0.1_p9`
 * You can look here https://pkgs.alpinelinux.org/packages?name=openjdk15

Build the `Dockerfile` and verify the image you built matches that version.

Ex.
```bash
./build_image 15.0.1_p9
```

Next, verify the built image matches that `java_version`.

For example, given the following output from `docker run --rm openzipkin/java:test -version`...
```
openjdk version "15.0.1" 2020-10-20
OpenJDK Runtime Environment (build 15.0.1+9-alpine-r0)
OpenJDK 64-Bit Server VM (build 15.0.1+9-alpine-r0, mixed mode)
```
The arg to `build_image` should be `15.0.1_p9`

To release the image, push a tag named the same as the arg to `build_image` (ex `15.0.1_p9`).
This will trigger a [Travis CI](https://travis-ci.org/openzipkin/docker-java) job to push the image.
