#!/bin/sh -e
export S3_HOST=$1
export S3_BUCKET=$2
export S3_ACCESS=$3
export S3_SECRET=$4
export TEST_ARTIFACTS_PATH=$5
export MC_HOST_bucket="https://${S3_ACCESS}:${S3_SECRET}@${S3_HOST}"
mkdir -p $GITHUB_WORKSPACE/test-artifacts
echo "Copying files from bucket/$S3_BUCKET/$TEST_ARTIFACTS_PATH/ to CI job at $GITHUB_WORKSPACE/test-artifacts/"
mc cp --recursive bucket/$S3_BUCKET/$TEST_ARTIFACTS_PATH/ $GITHUB_WORKSPACE/test-artifacts/
echo "Removing unnecessary files in test artifacts"
rm -rf $GITHUB_WORKSPACE/test-artifacts/scala* $GITHUB_WORKSPACE/test-artifacts/streams || echo "Some of the unnecessary test artifacts were not found."
echo "Removing S3 bucket with artifacts bucket/$S3_BUCKET/$TEST_ARTIFACTS_PATH"
mc rm --recursive --force bucket/$S3_BUCKET/$TEST_ARTIFACTS_PATH
