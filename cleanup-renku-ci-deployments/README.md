# Cleanup Old Renku CI Deployments

This action cleans up old CI renku deployments.

The action has the following regex hardcoded for finding the namespaces and helm releases in which it operates:
`.+-ci-.+|^ci-.+`. This is to ensure that it does not affect other deployments that should be more permanent, such
as the main dev deployment or developers' deployments.

It uses the following parameters, passed in as environment variables:
- `RENKUBOT_KUBECONFIG` (required) - the kubeconfig used to run the `helm` and `kubectl` commands
- `GITLAB_TOKEN` (required) - the Gitlab token used to cleanup the client applications for the CI deployment
- `KUBECONFIG` (optional, defaults to `/.kubeconfig`) - the location where kubeconfig file will be saved
- `HELM_RELEASE_REGEX` (optional, defaults to `.*`) - additional regex to apply on top of the regex used to find CI deployments
- `MAX_AGE_SECONDS` (optional, defaults to 604800 i.e. 1 week) - the age at or after which deployments are deleted, if set to zero (or negative) the deployment is immedidately deleted

The intended use of this action is to be setup as a scheduled workflow in github
that runs periodically and cleans up old CI renku deploments.
