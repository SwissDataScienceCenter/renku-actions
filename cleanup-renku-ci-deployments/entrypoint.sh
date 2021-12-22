#!/bin/sh

if test -z "$RENKUBOT_KUBECONFIG" ; then
    echo 'Please specify a kubeconfig that can be used for the helm and kubectl commands.'
    exit 1
fi

if test -z "$GITLAB_TOKEN" ; then
    echo 'Please specify a GITLAB TOKEN.'
    exit 1
fi

echo "$RENKUBOT_KUBECONFIG" > "$KUBECONFIG" && chmod 400 "$KUBECONFIG"

KUBECONFIG=${KUBECONFIG:-"/.kubeconfig"}
HELM_CI_RELEASE_REGEX=".+-ci-.+|^ci-.+"
HELM_RELEASE_REGEX="${HELM_RELEASE_REGEX:=".*"}"
K8S_CI_NAMESPACE_REGEX=".+-ci-.+|^ci-.+"
MAX_AGE_SECONDS=${MAX_AGE_SECONDS:=604800}
GITLAB_URL="https://dev.renku.ch/gitlab"

echo "Looking for CI releases with regex $HELM_RELEASE_REGEX."
echo "Looking in namespaces with regex $K8S_CI_NAMESPACE_REGEX."
echo "Age threshold for deletion is $MAX_AGE_SECONDS seconds."

# get a list of all applicable namespaces
NAMESPACES=$(kubectl get namespaces -o json | jq -r ".items | map(.metadata.name | select(test(\"$K8S_CI_NAMESPACE_REGEX\"))) | .[]")
NOW=$(date +%s)
for NAMESPACE in $NAMESPACES
do
    # get a list of all applicable releases
    RELEASES=$(helm -n $NAMESPACE list --all -f "$HELM_CI_RELEASE_REGEX" -o json | jq -r " map(.name | select(test(\"$HELM_RELEASE_REGEX\"))) | .[]")
    for RELEASE in $RELEASES
    do
        echo "Checking release $RELEASE in namespace $NAMESPACE."
        # extract last deployed date and convert to unix epoch
        LAST_DEPLOYED_AT=$(helm -n $NAMESPACE history $RELEASE -o json | jq -r 'last | .updated | sub("\\.[0-9]{6}.*$"; "Z") | fromdateiso8601')
        AGE_SECONDS=$(expr $NOW - $LAST_DEPLOYED_AT)
        if [ $AGE_SECONDS -ge $MAX_AGE_SECONDS ] || [ $MAX_AGE_SECONDS -le 0 ]
        then
            # remove any jupyterservers - they have finalizers that prevent the namespces to be deleted
            SERVERS=$(kubectl -n $NAMESPACE get jupyterservers -o json | jq -r '.items | .[].metadata.name') 
            for SERVER in $SERVERS
            do
                echo "Deleting jupyterserver $SERVER in namespace $NAMESPACE."
                kubectl -n $NAMESPACE delete --wait --cascade="foreground" jupyterserver
            done
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
            # remove the namespace
            echo "Deleting namespace $NAMESPACE"
            kubectl delete namespace $NAMESPACE --wait
        else
            echo "Release $RELEASE in namespace $NAMESPACE age is $AGE_SECONDS, not >= to $MAX_AGE_SECONDS, skipping."
        fi
    done
done
