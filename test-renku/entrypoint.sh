#!/bin/sh

if test -z "$RENKUBOT_KUBECONFIG" ; then
    echo 'Please specify a kubeconfig that can be used for the helm and kubectl commands.'
    exit 1
fi

if test -z "$RENKU_RELEASE" ; then
    echo 'Please specify the name of the helm renku release that should be tested.'
    exit 1
fi

export KUBECONFIG=${KUBECONFIG:-"$PWD/.kubeconfig"}
RENKU_NAMESPACE=${RENKU_NAMESPACE:-$RENKU_RELEASE}
TEST_TIMEOUT_MINS=${TEST_TIMEOUT_MINS:-60}
echo "$RENKUBOT_KUBECONFIG" > "$KUBECONFIG" && chmod 400 "$KUBECONFIG"

echo "Starting tests for release $RENKU_RELEASE in namespace $RENKU_NAMESPACE."
helm --kubeconfig $KUBECONFIG -n $RENKU_NAMESPACE test --timeout ${TEST_TIMEOUT_MINS}m --logs $RENKU_RELEASE
