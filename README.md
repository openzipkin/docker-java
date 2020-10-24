`openzipkin/java` is a minimal Docker image based on [azul/zulu-openjdk-alpine](https://hub.docker.com/r/azul/zulu-openjdk-alpine).

On Dockerhub: [openzipkin/java](https://hub.docker.com/r/openzipkin/java/) there will be two tags
per version. The one ending in `-jre` is a minimal build including modules Zipkin related images
need. The unqualified is a JDK that also includes Maven.

## Release process
The Docker build is driven by `--build-arg zulu_tag`. The value of this must be Zulu's most-specific
Java 8 tag, ex `6u119-6.22.0.3`.
 * You can look here https://hub.docker.com/r/azul/zulu-openjdk-alpine/tags?page=1&name=8

Build the `Dockerfile` and verify the image you built matches that tag.
Ex. `docker build -t openzipkin/java:test-jre --build-arg zulu_tag=6u119-6.22.0.3 .`

Next, verify the built image matches that `zulu_tag`.

For example, given the following output from `docker run --rm openzipkin/java:test-jre -version`...
```
openjdk version "1.6.0-119"
OpenJDK Runtime Environment (Zulu 6.22.0.3-linux64) (build 1.6.0-119-b119)
OpenJDK 64-Bit Server VM (Zulu 6.22.0.3-linux64) (build 23.77-b119, mixed mode)
```
The `zulu_tag` arg should be `6u119-6.22.0.3`

To release the image, push a tag named the same as the `zulu_tag` you built (ex `6u119-6.22.0.3`).
This will trigger a [Travis CI](https://travis-ci.org/openzipkin/docker-java) job to push the image.

Note: The upstream Zulu repository has a monthly release cadence. Maintainers should [watch the repo](https://github.com/zulu-openjdk/zulu-openjdk/watchers),
in case a pull request corresponds to a release. Since not all releases correspond to pull requests,
another way is to just check again at each month end.
