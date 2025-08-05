#!/bin/bash
set -e

if test -z "$GITLAB_TOKEN"; then
    echo 'Please specify a GITLAB TOKEN.'
    exit 1
fi

export KUBECONFIG=${KUBECONFIG:-"$PWD/.kubeconfig"}
if [ -n "$RENKUBOT_KUBECONFIG" ]; then
    echo "$RENKUBOT_KUBECONFIG" >"$KUBECONFIG" && chmod 400 "$KUBECONFIG"
fi

HELM_CI_RELEASE_REGEX=".+-ci-.+|^ci-.+"
HELM_RELEASE_REGEX="${HELM_RELEASE_REGEX:=".*"}"
K8S_CI_NAMESPACE_REGEX=".+-ci-.+|^ci-.+"
MAX_AGE_SECONDS=${MAX_AGE_SECONDS:=604800}
GITLAB_URL="https://gitlab.dev.renku.ch"
DELETE_NAMESPACE=${DELETE_NAMESPACE:="false"}

echo "Kubeconfig is at $KUBECONFIG."
KUBECONFIG_LINES=$(wc -l $KUBECONFIG)
echo "Kubeconfig is $KUBECONFIG_LINES long."
echo "GitLab URL is $GITLAB_URL"
echo "Looking for CI releases with regex $HELM_RELEASE_REGEX."
echo "Looking in namespaces with regex $K8S_CI_NAMESPACE_REGEX."
echo "Age threshold for deletion is $MAX_AGE_SECONDS seconds."
echo "Delete namespace: $DELETE_NAMESPACE"

NOW=$(date +%s)
NAMESPACES=$(kubectl get namespaces -o json | jq -cr ".items | map(select(.metadata.name | test(\"$K8S_CI_NAMESPACE_REGEX\"))) | .[].metadata.name")
for NAMESPACE in $NAMESPACES 
do
    RELEASES=$(helm list -n $NAMESPACE --all -f "$HELM_CI_RELEASE_REGEX" -o json | jq -cr "map(select(.name | test(\"$HELM_RELEASE_REGEX\"))) | .[].name")
    for RELEASE in $RELEASES
    do
        if [[ ! -z $RELEASE ]] && [[ ! -z $NAMESPACE ]]
        then
            echo "Checking release $RELEASE in namespace $NAMESPACE."
            # extract last deployed date and convert to unix epoch
            LAST_DEPLOYED_AT=$(helm -n $NAMESPACE history $RELEASE -o json | jq -r 'last | .updated | sub("\\.[0-9]{6}.*$"; "Z") | fromdateiso8601')
            AGE_SECONDS=$(expr $NOW - $LAST_DEPLOYED_AT)
            if [[ $AGE_SECONDS -ge $MAX_AGE_SECONDS ]] || [[ $MAX_AGE_SECONDS -le 0 ]]
            then
                # remove any jupyterservers - they have finalizers that prevent the namespces to be deleted
                echo "Deleting all JupyterServers in namespace $NAMESPACE."
                kubectl -n $NAMESPACE delete --all --wait --cascade="foreground" jupyterserver
                # remove any amaltheasessions - they have finalizers that prevent the namespces to be deleted
                echo "Deleting all AmaltheaSessions in namespace $NAMESPACE."
                kubectl -n $NAMESPACE delete --all --wait --cascade="foreground" amaltheasession
                # remove the gitlab app
                APPS=$(curl -s ${GITLAB_URL}/api/v4/applications -H "private-token: ${GITLAB_TOKEN}" | jq -r ".[] | select(.application_name == \"${RELEASE}\") | .id")
                for APP in $APPS
                do
                    echo "Deleting Gitlab application client $APP."
                    curl -X DELETE ${GITLAB_URL}/api/v4/applications/${APP} -H "private-token: ${GITLAB_TOKEN}"
                done
                # delete the helm chart
                echo "Deleting release $RELEASE in namespace $NAMESPACE, with age $AGE_SECONDS."
                helm -n $NAMESPACE delete $RELEASE
                # wait for helm release to be fully deleted
                kubectl -n $NAMESPACE get deployments -o json | jq -r '.items | .[].metadata.name' | xargs -r kubectl -n $NAMESPACE wait --for=delete deployment
                kubectl -n $NAMESPACE get statefulsets -o json | jq -r '.items | .[].metadata.name' | xargs -r kubectl -n $NAMESPACE wait --for=delete statefulset
                # remove the namespace if required
                if [ "$DELETE_NAMESPACE" = "true" ]
                then
                    echo "Deleting namespace $NAMESPACE"
                    kubectl delete namespace $NAMESPACE --wait
                fi
            else
                echo "Release $RELEASE in namespace $NAMESPACE age is $AGE_SECONDS, not >= to $MAX_AGE_SECONDS, skipping."
            fi
        else
            echo "Release $RELEASE and/or $NAMEPSACE are empty."
        fi
    done
    if [[ "$DELETE_NAMESPACE" = "true" ]] && [[ ! -z $NAMESPACE ]] && [[ -z $RELEASES ]] && [[ $NAMESPACE =~ $HELM_RELEASE_REGEX ]]
    then
        # Remove the namespace if there are no releases in it 
        # and the namespace name matches the name of the release - all CI deployments follow this pattern.
        # This addresses the case when a CI deployment does not persist but its namespace persists,
        # so when the PR is closed only the namespace in k8s remains and should be cleaned up.
        echo "Deleting namespace $NAMESPACE"
        kubectl delete namespace $NAMESPACE --wait
    fi
done
