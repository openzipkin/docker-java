`openzipkin/jre-full` is a minimal JRE Docker image based on [azul/zulu-openjdk-alpine](https://hub.docker.com/r/azul/zulu-openjdk-alpine).

On Dockerhub: [openzipkin/jre-full](https://hub.docker.com/r/openzipkin/jre-full/)

## Release process

New versions are built on [Travis CI](https://travis-ci.org/openzipkin/docker-jre-full). To trigger a build, push a new tag to GitHub. The tag will be the Docker tag assigned to the newly built image. Name the tag according to the JDK variant use.

For example, with the following output from `docker run --rm (image built) -version`:
```
openjdk version "15" 2020-09-15
OpenJDK Runtime Environment Zulu15.27+17-CA (build 15+36)
OpenJDK 64-Bit Server VM Zulu15.27+17-CA (build 15+36, mixed mode)
```

You would name the tag `15.0.0-15.27.17`, which makes sense as it corresponds to...
 * Zulu's most-specific tag the JRE image https://hub.docker.com/r/azul/zulu-openjdk-alpine/tags?page=1&name=15

Note: The upstream Zulu repository has a monthly release cadence. Maintainers should [watch the repo](https://github.com/zulu-openjdk/zulu-openjdk/watchers),
in case a pull request corresponds to a release. Since not all releases correspond to pull requests,
another way is to just check again at each month end.
