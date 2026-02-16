#!/bin/sh
set -e

source /app/.venv/bin/activate

RENKU_NAMESPACE=${RENKU_NAMESPACE:-$RENKU_RELEASE}
KUBERNETES_CLUSTER_FQDN=${KUBERNETES_CLUSTER_FQDN:-"dev.renku.ch"}

# set GitLab URL
export GITLAB_URL="https://gitlab.dev.renku.ch"
export REGISTRY_FQDN="registry.dev.renku.ch"
export TLS_SECRET_NAME="${RENKU_RELEASE}-ch-tls"

# set up docker credentials
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

# set up kube context and values file
if [ -n "$RENKUBOT_KUBECONFIG" ]; then
  echo "$RENKUBOT_KUBECONFIG" >"$KUBECONFIG" && chmod 400 "$KUBECONFIG"
fi

cp $RENKU_VALUES $RENKU_VALUES_FILE

# Set the FQDN in the values file
export FQDN="${RENKU_RELEASE}.${KUBERNETES_CLUSTER_FQDN}"
yq eval ".amalthea-sessions.deployCrd = false" -i $RENKU_VALUES_FILE
yq eval '.global.renku.domain = strenv(FQDN)' -i $RENKU_VALUES_FILE
yq eval '.ingress.hosts[0] = strenv(FQDN)' -i $RENKU_VALUES_FILE
yq eval '.ingress.tls[0].hosts[0] = strenv(FQDN)' -i $RENKU_VALUES_FILE
yq eval '.ingress.tls[0].secretName = strenv(TLS_SECRET_NAME)' -i $RENKU_VALUES_FILE
yq eval '.global.gitlab.url = strenv(GITLAB_URL)' -i $RENKU_VALUES_FILE
yq eval '.global.gitlab.registry.host = strenv(REGISTRY_FQDN)' -i $RENKU_VALUES_FILE

# Add ingress annotation only if ENABLE_NGINX_INGRESS is set
if [ -n "$ENABLE_NGINX_INGRESS" ]; then
  yq eval '.ingress.annotations."kubernetes.io/ingress.class" = "nginx"' -i $RENKU_VALUES_FILE
fi

# register the GitLab app
if test -n "$GITLAB_TOKEN" ; then
  gitlab_app=$(curl -s -X POST ${GITLAB_URL}/api/v4/applications \
                        -H "private-token: $GITLAB_TOKEN" \
                        --data "name=${RENKU_RELEASE}" \
                        --data "redirect_uri=https://${RENKU_RELEASE}.${KUBERNETES_CLUSTER_FQDN}/auth/realms/Renku/broker/dev-renku/endpoint https://${RENKU_RELEASE}.${KUBERNETES_CLUSTER_FQDN}/api/auth/gitlab/token https://${RENKU_RELEASE}.${KUBERNETES_CLUSTER_FQDN}/api/auth/callback" \
                        --data "scopes=api read_user read_repository read_registry openid")
  export APP_ID=$(echo $gitlab_app | jq -r '.application_id')
  export APP_SECRET=$(echo $gitlab_app | jq -r '.secret')

  # gateway gitlab app/secret
  yq eval '.gateway.gitlabClientId = strenv(APP_ID)' -i $RENKU_VALUES_FILE
  yq eval '.gateway.gitlabClientSecret = strenv(APP_SECRET)' -i $RENKU_VALUES_FILE
fi

# create namespace and ignore error in case it already exists
kubectl create namespace "${RENKU_NAMESPACE}" || true
kubectl label ns "${RENKU_NAMESPACE}" "renku.io/ci-deployment=true"

if [ -n "$PR_URL" ]; then
  # NOTE: That a full url cannot be used as a label value because label values have a more restricted
  # set of characters that are allowed and some of the special characters in urls are possible in annotations
  # but not for labels.
  kubectl patch ns "${RENKU_NAMESPACE}" --patch "{\"metadata\": {\"annotations\": {\"renku.io/pr-url\": \"${PR_URL}\"}}}"
fi

# deploy renku - reads config from environment variables
helm repo add renku https://swissdatasciencecenter.github.io/helm-charts
helm repo update

python3 /deploy-dev-renku.py
