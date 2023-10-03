#!/bin/sh
set -xe

if echo $GITHUB_REF | grep "tags" - > /dev/null; then
  CHART_TAG="--tag $(echo ${GITHUB_REF} | cut -d/ -f3)"
fi

if [ ! -z "$IMAGE_PREFIX" ]; then
  IMAGE_PREFIX="--image-prefix ${IMAGE_PREFIX}"
fi

if [ -z "$CHARTPRESS_SPEC_DIR" ]; then
  CHARTPRESS_SPEC_DIR="."
fi

# log in to docker
echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin

# if this is not run then git complains that the repo directory is untrusted and fails
git config --global --add safe.directory $PWD
# build and push the chart and images
cd $CHARTPRESS_SPEC_DIR
chartpress --push $CHART_TAG $IMAGE_PREFIX
