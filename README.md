`ghcr.io/openzipkin/java` is a minimal Docker image based on [azul/zulu-openjdk-alpine](https://hub.docker.com/r/azul/zulu-openjdk-alpine).

On GitHub Container Registry: [ghcr.io/openzipkin/java](https://github.com/orgs/openzipkin/packages/container/package/java) there will be two tags
per version. The one ending in `-jre` is a minimal build including modules Zipkin related images
need. The unqualified is a JDK that also includes Maven.

## Release process
The Docker build is driven by `--build-arg zulu_tag`. The value of this must be Zulu's most-specific
Java 8 tag, ex `8u272-8.50.0.21-jre-headless`.
 * You can look here https://hub.docker.com/r/azul/zulu-openjdk-alpine/tags?page=1&name=8

Build the `Dockerfile` and verify the image you built matches that tag.
Ex. `docker build -t openzipkin/java:test-jre --build-arg zulu_tag=8u272-8.50.0.21-jre-headless .`

Next, verify the built image matches that `zulu_tag`.

For example, given the following output from `docker run --rm openzipkin/java:test-jre -version`...
```
openjdk version "1.8.0_272"
OpenJDK Runtime Environment (Zulu 8.50.0.21-CA-linux-musl-x64) (build 1.8.0_272-b17)
OpenJDK 64-Bit Server VM (Zulu 8.50.0.21-CA-linux-musl-x64) (build 25.272-b17, mixed mode)
```
The `zulu_tag` arg should be `8u272-8.50.0.21-jre-headless`

To release the image, push a tag named the same as the `zulu_tag` you built (ex `8u272-8.50.0.21-jre-headless`).
This will trigger a [Travis CI](https://travis-ci.org/openzipkin/docker-java) job to push the image.

Note: The upstream Zulu repository has a monthly release cadence. Maintainers should [watch the repo](https://github.com/zulu-openjdk/zulu-openjdk/watchers),
in case a pull request corresponds to a release. Since not all releases correspond to pull requests,
another way is to just check again at each month end.
