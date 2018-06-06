`openzipkin/jre-full` is a minimal but full JRE Docker image based on [openjdk:8-jre-alpine](https://github.com/docker-library/openjdk/blob/master/8/jdk/alpine/Dockerfile). 

On Dockerhub: [openzipkin/jre-full](https://hub.docker.com/r/openzipkin/jre-full/)

## Release process

New versions are built on [Travis CI](https://travis-ci.org/openzipkin/docker-jre-full). To trigger a build, push a new tag to GitHub. The tag will be the Docker tag assigned to the newly built image. Name the tag according to the JDK in use. For example `1.8.0_112`.