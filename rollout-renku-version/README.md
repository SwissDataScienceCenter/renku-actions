# Action for updating component version

This is a docker action that will update the Renku version (rollout) in the deployments managed by terraform.

## Sample usage

It can simply be used as a step in a GitHub actions job:

```yaml
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    - uses: SwissDataScienceCenter/renku/actions/rollout-renku-deployment@master
      env:
        GITHUB_TOKEN: ${{ secrets.CI_TOKEN }}
```

Note that the `CI_TOKEN` needs write permissions to your upstream repository.

## Configuration

You can set these environment variables:

| Variable name    | Default |
| ---------------- | --------|
| CHART_NAME       | renku   |
| GIT_EMAIL        | renku@datascience.ch |
| GIT_USER         | Renku Bot |
| UPSTREAM_REPO    | SwissDataScienceCenter/terraform-renku |
| UPSTREAM_BRANCH  | main |
| PRODUCTION_DIR   | gitops/production |
| EXCLUDE_CLUSTERS | rancher renku-dev |
