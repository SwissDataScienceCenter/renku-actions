#!/bin/bash
set -xe

if [ -z "$GITHUB_TOKEN" ]
then
  echo "Must specify GITHUB_TOKEN"
  exit 1
fi

# set up environment variables
UPSTREAM_REPO=${UPSTREAM_REPO:=SwissDataScienceCenter/terraform-renku}
UPSTREAM_BRANCH=${UPSTREAM_BRANCH:=main}
GIT_EMAIL=${GIT_EMAIL:=renku@datascience.ch}
GIT_USER=${GIT_USER:="Renku Bot"}
CHART_NAME=${CHART_NAME:=$(echo $GITHUB_REPOSITORY | cut -d/ -f2)}
PRODUCTION_DIR=${PRODUCTION_DIR:="gitops/production"}
DEV_DIR=${DEV_DIR:="renku-dev"}
RANCHER_DIR=${RANCHER_DIR:="rancher"}

# get the chart version
CHART_VERSION=$(yq r helm-chart/${CHART_NAME}/Chart.yaml version)

git clone --depth=1 --branch=${UPSTREAM_BRANCH} https://${GITHUB_TOKEN}@github.com/${UPSTREAM_REPO} deployment-repo
cd deployment-repo

# set up git
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"

# update renku version and push
git checkout -b auto-update/${CHART_NAME}-${CHART_VERSION} ${UPSTREAM_BRANCH}


# use current date
date=$(date +"%B %dth %Y")
clusters=$(ls -d ${PRODUCTION_DIR}/*)

for cluster in $clusters
do
  if [[ ! $cluster =~ $RANCHER_DIR && ! $cluster =~ $DEV_DIR ]];
  then
    yq w -i $cluster/main/charts/renku.yaml "spec.chart.spec.version" $CHART_VERSION
    sed -i "/Renku version/c\          ### Renku version $CHART_VERSION ($date)" $cluster/main/charts/renku.yaml
    sed -i "/Release Notes/c\          See the [Release Notes](https://github.com/${GITHUB_REPOSITORY}/releases/tag/$CHART_VERSION)" $cluster/main/charts/renku.yaml
  fi
done


git add .
git commit -m "chore: updating ${CHART_NAME} version to ${CHART_VERSION}"
git push origin auto-update/${CHART_NAME}-${CHART_VERSION}

# clean up
cd ..
rm -rf deployment-repo
