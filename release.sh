#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 version"
    echo "  version: the version output from building this image"
    exit 1
fi
version="$1"

case "$version" in
  1.7* )
    JAVA_RELEASE=7
    ;;
  1.8* )
    JAVA_RELEASE=8
    ;;
  * )
    echo "Invalid Java version. should be like 1.8.0_252-b09"
    exit 1
esac

docker build --build-arg java_release=${JAVA_RELEASE} -t "openzipkin/java:${version}" --target jdk .
docker build --build-arg java_release=${JAVA_RELEASE} -t "openzipkin/java:${version}-jre" --target jre .

docker push "openzipkin/java:${version}"
docker push "openzipkin/java:${version}-jre"

