#!/bin/sh -x

# Makes two images based on Alpine Linux. One for OpenJDK and another for a stripped JRE
set -eu

if [ $# -ne 1 ]; then
    echo "Usage: $0 java_version"
    echo "  version from https://pkgs.alpinelinux.org/packages?name=openjdk15: Ex. 15.0.1_p9-r0"
    exit 1
fi

ALPINE_VERSION=3.12.1
JAVA_VERSION="$1"
PLATFORMS="linux/amd64,linux/arm64"

# buildx is experimental
export DOCKER_CLI_EXPERIMENTAL=enabled
BUILDX="docker buildx build --progress plain \
--build-arg alpine_version=${ALPINE_VERSION} --label alpine-version=${ALPINE_VERSION} \
--build-arg java_version=${JAVA_VERSION} --label java-version=${JAVA_VERSION}"

# We need to build separately per arch to test to use -load https://github.com/docker/buildx/issues/59
# Testing multiple archs likely requires qemu: docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
for platform in $(echo $PLATFORMS|tr -s ',' ' '); do
  for target in jdk jre; do
    tag=openzipkin/java:test-${target}
    ${BUILDX} --target ${target} --tag ${tag} --platform=${platform} --load .
    docker run --rm ${tag} -version
  done
done

# If we got here, we assume the images can be trusted. Go ahead and push them
for target in jdk jre; do
  tag=ghcr.io/openzipkin/java:${JAVA_VERSION}
  if [ "$target" = "jre" ]; then tag=${tag}-jre; fi
  echo Pushing image ${tag}
  ${BUILDX} --target ${target} --tag ${tag} --platform=${PLATFORMS} --push .
done
