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


git clone --depth=1 --branch=${UPSTREAM_BRANCH} https://${GITHUB_TOKEN}@github.com/${UPSTREAM_REPO} deployment-repo
cd deployment-repo

# get the chart version
CHART_VERSION=$(yq r helm-chart/${CHART_NAME}/Chart.yaml version)

# set up git
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"

# update renku version and push
git checkout -b auto-update/${CHART_NAME}-${CHART_VERSION} ${UPSTREAM_BRANCH}

# use current date
date=$( date +"%B %dth %Y")

for cluster in hslu limited renkovid renkulab unifr
do
  yq w -i gitops/production/$cluster/main/charts/renku.yaml "spec.chart.spec.version" $CHART_VERSION
  sed -i "/Renku version/c\          ### Renku version $CHART_VERSION ($date)" gitops/production/$cluster/main/charts/renku.yaml
  sed -i "/Release Notes/c\          See the [Release Notes](https://github.com/${UPSTREAM_REPO}/releases/tag/$CHART_VERSION)" gitops/production/$cluster/main/charts/renku.yaml
done


git add .
git commit -m "chore: updating ${CHART_NAME} version to ${CHART_VERSION}"
git push origin auto-update/${CHART_NAME}-${CHART_VERSION}

# clean up
cd ..
rm -rf deployment-repo
