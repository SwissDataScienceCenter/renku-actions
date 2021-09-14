#!/bin/sh

# set up kube context and values file
echo "$RENKUBOT_KUBECONFIG" > "$KUBECONFIG" && chmod 400 "$KUBECONFIG"

# set namespace defaults
RENKU_NAMESPACE=${RENKU_NAMESPACE:-$RENKU_RELEASE}

# delete the PR namespace
kubectl delete ns $RENKU_NAMESPACE

# remove the gitlab app
apps=$(curl -s https://dev.renku.ch/gitlab/api/v4/applications -H "private-token: ${GITLAB_TOKEN}" | jq -r ".[] | select(.application_name == \"${RENKU_RELEASE}\") | .id")
for app in $apps
do
    curl -X DELETE https://dev.renku.ch/gitlab/api/v4/applications/${app} -H "private-token: ${GITLAB_TOKEN}"
done
