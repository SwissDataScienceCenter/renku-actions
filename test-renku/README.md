# Run Renku Acceptance tests

This is a composite action that:
- sets up helm
- run the helm tests
- downloads test results from S3
- optionally cleans up the CI deployment at the end
