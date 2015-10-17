`openzipkin/jre-full` is a minimal but full JRE Docker image based on [delitescere/jdk](https://github.com/delitescere/docker-zulu). It's created by removing the JDK and leaving only the JRE, then squashing the Docker image.

On Dockerhub: [openzipkin/jre-full](https://hub.docker.com/r/openzipkin/jre-full/)

## Release process

New versions are built on [Travis CI](https://travis-ci.org/openzipkin/docker-jre-full). To trigger a build, push a new tag to GitHub. The tag will be the Docker tag assigned to the newly built image, which is exactly the same as the Docker tag from `delitescere/jdk` used as the base of the build.
