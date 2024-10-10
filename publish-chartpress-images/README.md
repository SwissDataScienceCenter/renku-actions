# Action for pushing images and chart with chartpress

This is a docker action that will generate images and push them using chartpress.

## Sample usage

It can simply be used as a step in a GitHub actions job:

```yaml
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    - uses: SwissDataScienceCenter/renku/actions/publish-chartpress-images@master
      env:
        CHART_DIR: helm-chart/mychart  # path to the chart directory
        DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
        DOCKER_PASSWORD: ${{ secrest.DOCKER_PASSWORD }}
```

## Configuration

You can set these environment variables:

| Variable name        | Default     | Required |
| -------------------- | ----------- | ---------|
| CHART_DIR            | helm-chart/ | No       |
| DOCKER_PASSWORD      | None        | Yes      |
| DOCKER_USERNAME      | None        | Yes      |
| IMAGE_PREFIX         | None        | No       |
| CHARTPRESS_SPEC_DIR  | .           | No       |
| PUSH_LATEST          | None        | No       |

Note: setting the `PUSH_LATEST` variable to any non-zero value will trigger the publishing of
the images with the `latest` tag.
