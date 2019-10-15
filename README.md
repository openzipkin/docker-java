`openzipkin/jre-full` is a minimal but full [distroless JRE Docker image](https://github.com/GoogleContainerTools/distroless) based on [azul/zulu-openjdk-debian](https://github.com/zulu-openjdk/zulu-openjdk/tree/master/debian/11-latest).

On Dockerhub: [openzipkin/jre-full](https://hub.docker.com/r/openzipkin/jre-full/)

## Release process

New versions are built on [Travis CI](https://travis-ci.org/openzipkin/docker-jre-full). To trigger a build, push a new tag to GitHub. The tag will be the Docker tag assigned to the newly built image. Name the tag according to the JDK in use. For example `11.0.4`.
