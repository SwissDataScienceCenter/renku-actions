#!/bin/sh

if test -z "$RENKU_RELEASE"; then
    echo 'Please specify the name of the helm renku release that should be tested.'
    exit 1
fi

export KUBECONFIG=${KUBECONFIG:-"$PWD/.kubeconfig"}
if [ -n "$RENKUBOT_KUBECONFIG" ]; then
    echo "$RENKUBOT_KUBECONFIG" >"$KUBECONFIG" && chmod 400 "$KUBECONFIG"
fi
RENKU_NAMESPACE=${RENKU_NAMESPACE:-$RENKU_RELEASE}
TEST_TIMEOUT_MINS=${TEST_TIMEOUT_MINS:-60}

echo "Starting tests for release $RENKU_RELEASE in namespace $RENKU_NAMESPACE."
helm --kubeconfig $KUBECONFIG -n $RENKU_NAMESPACE test --timeout ${TEST_TIMEOUT_MINS}m --logs $RENKU_RELEASE
