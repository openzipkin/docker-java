`openzipkin/jre-full` is a minimal but full JRE Docker image based on [cantara/alpine-zulu-jdk8](https://github.com/Cantara/maven-infrastructure/tree/master/docker-baseimages/alpine-zulu-jdk8). It's created by removing the JDK and leaving only the JRE, then squashing the Docker image.

On Dockerhub: [openzipkin/jre-full](https://hub.docker.com/r/openzipkin/jre-full/)

## Release process

New versions are built on [Travis CI](https://travis-ci.org/openzipkin/docker-jre-full). To trigger a build, push a new tag to GitHub. The tag will be the Docker tag assigned to the newly built image. Since `cantara/alpine-zulu-jdk8` only pushes latest, name the tag according to the JDK in use. For example `1.8.0_112`.
