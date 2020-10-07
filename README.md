`openzipkin/java` is a minimal Docker image based on [azul/zulu-openjdk-alpine](https://hub.docker.com/r/azul/zulu-openjdk-alpine).

On Dockerhub: [openzipkin/java](https://hub.docker.com/r/openzipkin/java/) there will be two tags
per version. The one ending in `-jre` is a minimal build including modules Zipkin related images
need. The unqualified is a JDK that also includes Maven.

## Release process
New versions are built on [Travis CI](https://travis-ci.org/openzipkin/docker-java). To trigger a
build, push a new tag to GitHub. The tag will be the Docker tag assigned to the newly built image.
Name the tag according to the JDK in use.

If you built Java 8 like so: `docker build --build-arg java_release=8 -t openzipkin/java:test-jre .`

... you would look at the output from `docker run --rm openzipkin/java:test-jre -version`...
```
openjdk version "1.8.0_252"
OpenJDK Runtime Environment (IcedTea 3.16.0) (Alpine 8.252.09-r1)
OpenJDK 64-Bit Server VM (build 25.252-b09, mixed mode)
```

... and name the tag `1.8.0_252-b09`.
