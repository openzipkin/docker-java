`openzipkin/jre-full` is a minimal but full [distroless JRE Docker image](https://github.com/GoogleContainerTools/distroless) based on [azul/zulu-openjdk-debian](https://github.com/zulu-openjdk/zulu-openjdk/tree/master/debian/11-latest).

On Dockerhub: [openzipkin/jre-full](https://hub.docker.com/r/openzipkin/jre-full/)

## Release process

New versions are built on [Travis CI](https://travis-ci.org/openzipkin/docker-jre-full). To trigger a build, push a new tag to GitHub. The tag will be the Docker tag assigned to the newly built image. Name the tag according to the JDK variant use.

For example, with the following output from `docker run (image built) -version`:
```
openjdk version "14.0.2" 2020-07-14
OpenJDK Runtime Environment Zulu14.29+23-CA (build 14.0.2+12)
OpenJDK 64-Bit Server VM Zulu14.29+23-CA (build 14.0.2+12, mixed mode)
```

You would name the tag `14.0.2-14.29.23`, which makes sense as it corresponds to...
 * Zulu's most-specific tag the JRE image https://hub.docker.com/r/azul/zulu-openjdk-debian/tags?page=1&name=14
 * Zulu source directory of their Dockerfile https://github.com/zulu-openjdk/zulu-openjdk/tree/master/14.0.2-14.29.23
