#!/bin/bash
# Takes a minimal but full JDK image from azul/zulu-openjdk-debian
# Removes the JDK and keeps the full JRE
# Then squashes to minimize the image size
# The resulting images are expected to change rarely, if ever

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 version"
    echo "  version: the version output from building azul/zulu-openjdk-debian "
    exit 1
fi
version="$1"
tag="openzipkin/jre-full:$version"

docker build --squash -t "$tag" .

docker push "$tag"
