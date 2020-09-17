`openzipkin/jre-full` is a minimal but full Alpine JRE Docker 1.8 image.

On Dockerhub: [openzipkin/jre-full](https://hub.docker.com/r/openzipkin/jre-full/)

## Release process

New versions are built on [Travis CI](https://travis-ci.org/openzipkin/docker-jre-full). To trigger a build, push a new tag to GitHub. The tag will be the Docker tag assigned to the newly built image. Name the tag according to the JDK in use.

The tag will be the Docker tag assigned to the newly built image. Name the tag according to the JDK variant use.

For example, with the following output from `docker run (image built) java -version`:
```
openjdk version "1.8.0_252"
OpenJDK Runtime Environment (IcedTea 3.16.0) (Alpine 8.252.09-r1)
OpenJDK 64-Bit Server VM (build 25.252-b09, mixed mode)
```

You would name the tag `1.8.0_252-b09`.
