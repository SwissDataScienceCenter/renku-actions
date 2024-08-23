# Deploy Renku action

This action is used to deploy renku in continuous integration pipelines.

The script `deploy-dev-renku.py` can be used stand-alone from a terminal to
quickly get a renku deployment up-and-running. The script makes it easy to mix
and match different component versions by automating the process of building
and preparing the charts.

## Usage

To use the action, add a snippet like this one to your GitHub actions workflow:

```yaml
deploy-pr:
  if: github.event.action != 'closed'
  needs: [cleanup-previous-runs, check-deploy]
  runs-on: ubuntu-latest
  environment:
    name: ci-renku-${{ github.event.number }}
  steps:
    - uses: actions/checkout@v3
    - name: renku build and deploy
    if: needs.check-deploy.outputs.pr-contains-string == 'true'
    uses: SwissDataScienceCenter/renku-actions/deploy-renku@v0.3.2
    env:
      DOCKER_PASSWORD: ${{ secrets.RENKU_DOCKER_PASSWORD }}
      DOCKER_USERNAME: ${{ secrets.RENKU_DOCKER_USERNAME }}
      GITLAB_TOKEN: ${{ secrets.DEV_GITLAB_TOKEN }}
      KUBECONFIG: "${{ github.workspace }}/renkubot-kube.config"
      RENKU_ANONYMOUS_SESSIONS: true
      RENKU_RELEASE: ci-renku-${{ github.event.number }}
      RENKU_VALUES_FILE: "${{ github.workspace }}/values.yaml"
      RENKU_VALUES: ${{ secrets.CI_RENKU_VALUES }}
      RENKUBOT_KUBECONFIG: ${{ secrets.RENKUBOT_DEV_KUBECONFIG }}
      TEST_ARTIFACTS_PATH: "tests-artifacts-${{ github.sha }}"
      renku: "@${{ github.head_ref }}"
      renku_core: "${{ needs.check-deploy.outputs.renku-core }}"
      renku_gateway: "${{ needs.check-deploy.outputs.renku-gateway }}"
      renku_graph: "${{ needs.check-deploy.outputs.renku-graph }}"
      renku_notebooks: "${{ needs.check-deploy.outputs.renku-notebooks }}"
      renku_ui: "${{ needs.check-deploy.outputs.renku-ui }}"
      renku_data_services: "${{ needs.check-deploy.outputs.renku-data-services }}"
      amalthea: "${{ needs.check-deploy.outputs.amalthea }}"
      amalthea_sessions: "${{ needs.check-deploy.outputs.amalthea-sessions }}"
      secrets_storage: "${{ needs.check-deploy.outputs.secrets-storage}}"
      renku_search: "${{ needs.check-deploy.outputs.renku-search }}"
      extra_values: "${{ needs.check-deploy.outputs.extra-values }}"
```

Note that the component versions `renku`, `renku_core` etc. come from the
[`check-pr-description`
action](https://github.com/SwissDataScienceCenter/renku-actions/tree/master/check-pr-description).
