#!/bin/bash
set -xe

if [ -z "$GITHUB_TOKEN" ]
then
  echo "Must specify GITHUB_TOKEN"
  exit 1
fi

if [[ $GITHUB_REF =~ "tags" ]]
then
  COMPONENT_TAG="--tag $(echo ${GITHUB_REF} | cut -d/ -f3)"
fi

# set up environment variables
UPSTREAM_REPO=${UPSTREAM_REPO:=SwissDataScienceCenter/renku}
UPSTREAM_BRANCH=${UPSTREAM_BRANCH:=master}
GIT_EMAIL=${GIT_EMAIL:=renku@datascience.ch}
GIT_USER=${GIT_USER:="Renku Bot"}
COMPONENT_NAME=${COMPONENT_NAME:=$(echo $GITHUB_REPOSITORY | cut -d/ -f2)}

# build this chart to get the version
chartpress --skip-build $COMPONENT_TAG
COMPONENT_VERSION=$(yq r helm-chart/${COMPONENT_NAME}/Chart.yaml version)

git clone --depth=1 --branch=${UPSTREAM_BRANCH} https://${GITHUB_TOKEN}@github.com/${UPSTREAM_REPO} upstream-repo

# update the upstream repo
cd upstream-repo

# set up git
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"

# update the chart requirements and push
git checkout -b auto-update/${COMPONENT_NAME}-${COMPONENT_VERSION} ${UPSTREAM_BRANCH}
yq m -x -i helm-chart/renku/values.yaml ../helm-chart/${COMPONENT_NAME}/values.yaml
yamlfmt helm-chart/renku/values.yaml

git add helm-chart/renku/values.yaml
git commit -m "chore: updating ${COMPONENT_NAME} version to ${COMPONENT_VERSION}"
git push origin auto-update/${COMPONENT_NAME}-${COMPONENT_VERSION}

# clean up
cd ..
rm -rf upstream-repo
