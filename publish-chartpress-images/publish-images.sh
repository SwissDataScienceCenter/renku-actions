#!/bin/sh
set -xe

source /app/.venv/bin/activate

if echo $GITHUB_REF | grep "tags" - > /dev/null; then
  CHART_TAG="--tag $(echo ${GITHUB_REF} | cut -d/ -f3)"
fi

if [ ! -z "$IMAGE_PREFIX" ]; then
  IMAGE_PREFIX="--image-prefix ${IMAGE_PREFIX}"
fi

if [ -z "$CHARTPRESS_SPEC_DIR" ]; then
  CHARTPRESS_SPEC_DIR="."
fi

PLATFORM_ARGS=""
BUILDER_ARG=""
if [ ! -z "$PLATFORMS" ]; then
  # setting up docker-buildx for multi-platform builds
  docker buildx create --name multiarch --use
  docker buildx inspect --bootstrap

  for platform in $(echo $PLATFORMS | tr ',' ' '); do
    PLATFORM_ARGS="$PLATFORM_ARGS --platform $platform"
  done
  BUILDER_ARG="--builder docker-buildx"
fi

# log in to docker
echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin

# if this is not run then git complains that the repo directory is untrusted and fails
git config --global --add safe.directory $PWD
# build and push the chart and images
cd $CHARTPRESS_SPEC_DIR
chartpress --push $CHART_TAG $IMAGE_PREFIX $PLATFORM_ARGS $BUILDER_ARG

if [ ! -z "$PUSH_LATEST" ]; then
    echo "Pushing images with 'latest' tags"
    chartpress --push --tag latest $IMAGE_PREFIX $PLATFORM_ARGS $BUILDER_ARG
fi
