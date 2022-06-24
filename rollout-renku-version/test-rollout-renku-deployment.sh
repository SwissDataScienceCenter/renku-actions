#!/bin/bash
set -xe

# get the chart version
CHART_VERSION="1.2.3"
UPSTREAM_REPO=${UPSTREAM_REPO:=SwissDataScienceCenter/renku}

# use current date
date=$( date +"%B %dth %Y")

for cluster in hslu limited renkovid renkulab unifr
do
  yq w -i gitops/production/$cluster/main/charts/renku.yaml "spec.chart.spec.version" "$CHART_VERSION"
  sed -i "/Renku version/c\          ### Renku version $CHART_VERSION ($date)" gitops/production/$cluster/main/charts/renku.yaml
  sed -i "/Release Notes/c\          See the [Release Notes](https://github.com/${UPSTREAM_REPO}/releases/tag/$CHART_VERSION)" gitops/production/$cluster/main/charts/renku.yaml
done
