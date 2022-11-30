# Run Cypress-based acceptance tests

This is a composite action that:
- clones the renku repo and checks out the specified ref
- runs the cypress acceptance tests from the renku repo
- saves the results as an artifact

# Interaction with Selenium-based acceptance tests

The `test-renku-cypress` action **does not** tear down the deployment, but the `test-renku` action to run the Selenium-based tests does, and some care needs to be taken when running the Cypress tests without running the Selenium tests.

To run the cypress tests without the selenium tests, it is be necessary to persist the deployment:

```
/deploy #persist #notest #cypress
```

## Example use

```yaml
steps:
- name: Extract renku repo ref
  run: echo "RENKU=`echo '${{ needs.check-deploy.outputs.renku }}' | cut -d'@' -f2`" >> $GITHUB_ENV
- uses: SwissDataScienceCenter/renku-actions/test-renku-cypress
  with:
    gitlab-token: ${{ secrets.DEV_GITLAB_TOKEN }}
    renku-release: renku-ci-ui-${{ github.event.number }}
    test-user-password: ${{ secrets.RENKU_BOT_DEV_PASSWORD }}
    renku: "${{ needs.check-deploy.outputs.renku }}"
```

(Note the need to process the `check-deploy.outputs.renku` value before passing to this action. The `check-pr-description` action outputs refs that begin with `@`, but the clone command used here expects the ref name without an `@`.)
## Inputs

| Variable name        | Default     | Required |
| -------------------- | ----------- | ---------|
| gitlab-token         | None        | Yes      |
| renku-release        | None        | Yes      |
| test-user-password   | None        | Yes      |
| renku                | master      | No       |
| test-timeout-mins    | 60          | No       |
