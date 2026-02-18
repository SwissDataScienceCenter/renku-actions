# Run Renku Acceptance tests

This is a composite action that:
- sets up helm
- run the helm tests
- downloads test results from S3

## Example use
```yaml
steps:
- uses: SwissDataScienceCenter/renku-actions/test-renku
  with:
    kubeconfig: /home/jdoe/.kube/config
    renku-release: ci-renku-${{ github.event.number }}
    ci-renku-values: ${{ secrets.CI_RENKU_VALUES }}
```

## Inputs

| Variable name        | Default     | Required |
| -------------------- | ----------- | ---------|
| kubeconfig           | None        | Yes      |
| renku-release        | None        | Yes      |
| test-timeout-mins    | 60          | No       |
| ci-renku-values      | None        | Yes      |
