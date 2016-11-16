#!/bin/bash
# Takes a minimal but full JDK image from cantara/alpine-zulu-jdk8
# Removes the JDK and keeps the full JRE
# Then squashes to minimize the image size
# The resulting images are expected to change rarely, if ever

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 version"
    echo "  version: a tag on the Docker image delitescere/jdk"
    exit 1
fi
version="$1"
tag="openzipkin/jre-full:$version"
fat_tag="${tag}-fat"

docker_squash="$(which docker-squash)"

docker build -t "$fat_tag" .

docker-squash -t "$tag" "$fat_tag"

docker push "$tag"
