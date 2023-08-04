#!/bin/sh
set -e

RENKU_NAMESPACE=${RENKU_NAMESPACE:-$RENKU_RELEASE}

# set GitLab URL
GITLAB_URL="https://gitlab.dev.renku.ch"

# set up docker credentials
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

# set up kube context and values file
echo "$RENKUBOT_KUBECONFIG" > "$KUBECONFIG" && chmod 400 "$KUBECONFIG"

export RENKU_VALUES_FILE="/renku-values.yaml"

# merge the secret and clear value files
printf "%s" "$RENKU_SECRET_VALUES" > $RENKU_VALUES_FILE
yq eval-all --inplace '. as $item ireduce ({}; . * $item )' $RENKU_VALUES_FILE $RENKU_CLEAR_VALUES_FILE

# replace the release name
sed --in-place "s/<replace>/${RENKU_RELEASE}/" $RENKU_VALUES_FILE

# register the GitLab app
if test -n "$GITLAB_TOKEN" ; then
  gitlab_app=$(curl -s -X POST ${GITLAB_URL}/api/v4/applications \
                        -H "private-token: $GITLAB_TOKEN" \
                        --data "name=${RENKU_RELEASE}" \
                        --data "redirect_uri=https://${RENKU_RELEASE}.dev.renku.ch/auth/realms/Renku/broker/dev-renku/endpoint https://${RENKU_RELEASE}.dev.renku.ch/api/auth/gitlab/token" \
                        --data "scopes=api read_user read_repository read_registry openid")
  export APP_ID=$(echo $gitlab_app | jq -r '.application_id')
  export APP_SECRET=$(echo $gitlab_app | jq -r '.secret')

  # gateway gitlab app/secret
  yq eval --inplace '.gateway.gitlabClientId = strenv(APP_ID)' $RENKU_VALUES_FILE
  yq eval --inplace '.gateway.gitlabClientSecret = strenv(APP_SECRET)' $RENKU_VALUES_FILE
fi

# create namespace and ignore error in case it already exists
kubectl create namespace ${RENKU_NAMESPACE} || true

# deploy renku - reads config from environment variables
helm repo add renku https://swissdatasciencecenter.github.io/helm-charts
helm repo update

python3 /deploy-dev-renku.py
