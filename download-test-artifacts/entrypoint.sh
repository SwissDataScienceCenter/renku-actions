#!/bin/sh -e
printf "%s" "$RENKU_VALUES" > values.yaml
export S3_HOST=$(yq '.tests.resultsS3.host' values.yaml -r)
export S3_ACCESS=$(yq '.tests.resultsS3.accessKey' values.yaml -r)
export S3_SECRET=$(yq '.tests.resultsS3.secretKey' values.yaml -r)
export S3_BUCKET=$(yq '.tests.resultsS3.bucket' values.yaml -r)
export MC_HOST_bucket="https://${S3_ACCESS}:${S3_SECRET}@${S3_HOST}"
mkdir -p $GITHUB_WORKSPACE/test-artifacts
echo "Copying files from bucket/$S3_BUCKET/$TEST_ARTIFACTS_PATH/ to CI job at $GITHUB_WORKSPACE/test-artifacts/"
mc cp --recursive bucket/$S3_BUCKET/$TEST_ARTIFACTS_PATH/ $GITHUB_WORKSPACE/test-artifacts/
echo "Removing unnecessary files in test artifacts"
rm -rf $GITHUB_WORKSPACE/test-artifacts/scala* $GITHUB_WORKSPACE/test-artifacts/streams || echo "Some of the unnecessary test artifacts were not found."
echo "Removing S3 bucket with artifacts bucket/$S3_BUCKET/$TEST_ARTIFACTS_PATH"
mc rm --recursive --force bucket/$S3_BUCKET/$TEST_ARTIFACTS_PATH
