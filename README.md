`openzipkin/jre-full` is a minimal but full [distroless JRE Docker image](https://github.com/GoogleContainerTools/distroless) based on [azul/zulu-openjdk-debian](https://github.com/zulu-openjdk/zulu-openjdk/tree/master/debian/11-latest).

On Dockerhub: [openzipkin/jre-full](https://hub.docker.com/r/openzipkin/jre-full/)

## Release process

New versions are built on [Travis CI](https://travis-ci.org/openzipkin/docker-jre-full). To trigger a build, push a new tag to GitHub. The tag will be the Docker tag assigned to the newly built image. Name the tag according to the JDK variant use.

For example, with the following output from `docker run (image built) -version`:
```
openjdk version "11.0.4" 2019-07-16 LTS
OpenJDK Runtime Environment Zulu11.33+15-CA (build 11.0.4+11-LTS)
OpenJDK 64-Bit Server VM Zulu11.33+15-CA (build 11.0.4+11-LTS, mixed mode)
```

You would name the tag `11.0.4-11.33`, which corresponds to the Zulu directory https://github.com/zulu-openjdk/zulu-openjdk/tree/master/11.0.4-11.33
