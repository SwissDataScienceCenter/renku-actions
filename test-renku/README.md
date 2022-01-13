# Run Renku Acceptance tests

This is a composite action that:
- sets up helm
- run the helm tests
- downloads test results from S3
- optionally cleans up the CI deployment at the end

## Example use
```yaml
steps:
- uses: SwissDataScienceCenter/renku-actions/test-renku
  with:
  renkubot-kubeconfig: ${{ secrets.RENKUBOT_DEV_KUBECONFIG }}
  renku-release: ci-renku-${{ github.event.number }}
  gitlab-token: ${{ secrets.DEV_GITLAB_TOKEN }}
  persist: "${{ needs.check-deploy.outputs.persist }}"
  ci-renku-values: ${{ secrets.CI_RENKU_VALUES }}
```

## Inputs

| Variable name        | Default     | Required |
| -------------------- | ----------- | ---------|
| renkubot-kubeconfig  | helm-chart/ | Yes      |
| renku-release        | None        | Yes      |
| gitlab-token         | None        | Yes      |
| persist              | false       | No       |
| test-timeout-mins    | 60          | No       |
| ci-renku-values      | None        | Yes      |
