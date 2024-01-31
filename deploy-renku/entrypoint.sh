#!/bin/sh
set -e

RENKU_NAMESPACE=${RENKU_NAMESPACE:-$RENKU_RELEASE}

# set GitLab URL
GITLAB_URL="https://gitlab.dev.renku.ch"

# set up docker credentials
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

# set up kube context and values file
echo "$RENKUBOT_KUBECONFIG" > "$KUBECONFIG" && chmod 400 "$KUBECONFIG"

# set up the values file
printf "%s" "$RENKU_VALUES" | sed "s/<replace>/${RENKU_RELEASE}/" > $RENKU_VALUES_FILE

# register the GitLab app
if test -n "$GITLAB_TOKEN" ; then
  gitlab_app=$(curl -s -X POST ${GITLAB_URL}/api/v4/applications \
                        -H "private-token: $GITLAB_TOKEN" \
                        --data "name=${RENKU_RELEASE}" \
                        --data "redirect_uri=https://${RENKU_RELEASE}.dev.renku.ch/auth/realms/Renku/broker/dev-renku/endpoint https://${RENKU_RELEASE}.dev.renku.ch/api/auth/gitlab/token https://${RENKU_RELEASE}.dev.renku.ch/api/auth/callback" \
                        --data "scopes=api read_user read_repository read_registry openid")
  APP_ID=$(echo $gitlab_app | jq -r '.application_id')
  APP_SECRET=$(echo $gitlab_app | jq -r '.secret')

  # gateway gitlab app/secret
  yq w -i $RENKU_VALUES_FILE "gateway.gitlabClientId" "$APP_ID"
  yq w -i $RENKU_VALUES_FILE "gateway.gitlabClientSecret" "$APP_SECRET"
fi

# create namespace and ignore error in case it already exists
kubectl create namespace ${RENKU_NAMESPACE} || true

# deploy renku - reads config from environment variables
helm repo add renku https://swissdatasciencecenter.github.io/helm-charts
helm repo update

python3 /deploy-dev-renku.py
