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
EXCLUDE_CLUSTERS=${EXCLUDE_CLUSTERS:="rancher renku-dev"}

# get the chart version
CHART_VERSION=$(yq r helm-chart/${CHART_NAME}/Chart.yaml version)

# set up git
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"

# use current date
DATE=$(date +"%B %dth %Y")

# get the list of clusters to update
git clone --depth=1 --branch=${UPSTREAM_BRANCH} https://${GITHUB_TOKEN}@github.com/${UPSTREAM_REPO} deployment-repo
cd deployment-repo
cluster_dirs=$(ls -d ${PRODUCTION_DIR}/*)
cd ..
rm -rf deployment-repo

for cluster_dir in $cluster_dirs
do
  cluster=$(echo "$cluster_dir" | awk -F "/" '{print $3}')
  if [[ ! $EXCLUDE_CLUSTERS =~ "$cluster" ]];
  then
    git clone --depth=1 --branch=${UPSTREAM_BRANCH} https://${GITHUB_TOKEN}@github.com/${UPSTREAM_REPO} deployment-repo
    cd deployment-repo

    # update renku version and push
    git checkout -b auto-update/${CHART_NAME}-${CHART_VERSION}-${cluster} ${UPSTREAM_BRANCH}

    yq -i '.spec.chart.spec.version = "$CHART_VERSION"' $cluster_dir/main/charts/renku.yaml
    sed -i "/Renku version/c\            ### Renku version $CHART_VERSION ($DATE)" $cluster_dir/main/charts/renku.yaml
    sed -i "/Release Notes/c\            See the [Release Notes](https://github.com/${GITHUB_REPOSITORY}/releases/tag/$CHART_VERSION)" $cluster_dir/main/charts/renku.yaml

    git add .
    git commit -m "chore: updating ${CHART_NAME} version to ${CHART_VERSION}"
    git push origin auto-update/${CHART_NAME}-${CHART_VERSION}-${cluster}

    # clean up
    cd ..
    rm -rf deployment-repo
  fi
done
