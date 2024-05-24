[![Gitter chat](http://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg)](https://gitter.im/openzipkin/zipkin)
[![Build Status](https://github.com/openzipkin/docker-java/workflows/test/badge.svg)](https://github.com/openzipkin/docker-java/actions?query=workflow%3Atest)

`ghcr.io/openzipkin/java` is a minimal OpenJDK [Alpine Linux](https://github.com/openzipkin/docker-alpine) image.

GitHub Container Registry: [ghcr.io/openzipkin/java](https://github.com/orgs/openzipkin/packages/container/package/java) includes:
 * `master` tag: latest commit
 * `MAJOR.MINOR.PATCH` tag: release corresponding to a [Current OpenJDK Version](https://pkgs.alpinelinux.org/packages?name=openjdk17)

Tags ending in `-jre` include only a JRE where unqualified tags include the full JDK, Maven, and a
few build utilities.

## Using this image
This is an internal base layer primarily used in [zipkin](https://github.com/openzipkin/zipkin).

To try the image, run the `java -version` command:
```bash
$ docker run --rm ghcr.io/openzipkin/java:17.0.11_p9 -version
openjdk version "17.0.11" 2024-04-16
OpenJDK Runtime Environment (build 17.0.11+9-alpine-r0)
OpenJDK 64-Bit Server VM (build 17.0.11+9-alpine-r0, mixed mode, sharing)
```

## Release process

Make sure you are on the right branch. If there is a branch prefixed JDK, it
may have workarounds applied for the version in question. The master branch is
always operable for the latest LTS JDKs that don't need workarounds.

Also, make sure you are using an LTS JDK. Any non-LTS would be an exception
basis and are unlikely to be consumed by Zipkin (primary reason for this repo).

Make sure the [Dockerfile](Dockerfile) has `docker_parent_image` set to the
[Current Alpine Version](https://www.alpinelinux.org/downloads/). If the image
doesn't yet exist, release it [here](https://github.com/openzipkin/docker-alpine)
before continuing. Notably, this avoids missing CVE fixes by mistake.

Build the [Dockerfile](Dockerfile) using the current version without the
revision classifier from here:
 * https://pkgs.alpinelinux.org/packages?name=openjdk17
```bash
# Note 17.0.11_p9 not 17.0.11_p9-r0!
./build-bin/build 17.0.11_p9
```

Next, verify the built image matches that version:
```bash
$ docker run --rm openzipkin/java:test -version
openjdk version "17.0.11" 2024-04-16
OpenJDK Runtime Environment (build 17.0.11+9-alpine-r0)
OpenJDK 64-Bit Server VM (build 17.0.11+9-alpine-r0, mixed mode, sharing)
```

To release the image, push a tag matching the arg to `build-bin/build` (ex `17.0.11_p9`).
This triggers a [GitHub Actions](https://github.com/openzipkin/docker-java/actions) job to push the image.

## java.lang.ClassNotFoundException

The image ending in `-jre` is stripped to only retain the minimal modules needed by Zipkin. This is
to make it as small as possible. If the `zipkin` or `zipkin-slim` images fail with a
`java.lang.ClassNotFoundException`, it may be related to the modules linked in the [Dockerfile][Dockerfile].

If the package begins with `java.`, `sun.` or `com.sun.`, it is likely a JRE module. To verify, use
`javap` without any other options. If a result is printed, you need to link a corresponding module.

For example, here's the result of `javax.sql.rowset.serial.SerialException`, which is in the module
`java.sql.rowset`:
```
$ javap javax.sql.rowset.serial.SerialException
Compiled from "SerialException.java"
public class javax.sql.rowset.serial.SerialException extends java.sql.SQLException {
  static final long serialVersionUID;
  public javax.sql.rowset.serial.SerialException();
  public javax.sql.rowset.serial.SerialException(java.lang.String);
}
```

## CVEs

This builds JDK and JRE images over our [Alpine Linux](https://github.com/openzipkin/docker-alpine)
base layer. If you have any platform CVEs that relate to the Alpine version, check there first and
cut a new version as necessary.

Specifically, this adds [Alpine's OpenJDK](https://pkgs.alpinelinux.org/packages?name=openjdk17)
package as well as Maven (to reduce image layers). If there is a concern about CVEs, check to see if
there is a newer JDK available and release it.

If the most recent has CVEs and the corresponding patch isn't yet released, check the [issues list](https://gitlab.alpinelinux.org/search?group_id=2&project_id=1&repository_ref=master&scope=issues&search=openjdk).
You may find another issue already, and if not you can make one with context. Sites who have needs
that cannot be met by open source support might consider building their own Java image and adding
zipkin to that directly.
