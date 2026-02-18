#!/bin/sh
set -e

# set up kube context and values file
echo "$RENKUBOT_KUBECONFIG" > "$KUBECONFIG" && chmod 400 "$KUBECONFIG"

# set namespace defaults
RENKU_NAMESPACE=${RENKU_NAMESPACE:-$RENKU_RELEASE}

# delete the PR namespace
kubectl delete ns $RENKU_NAMESPACE
