#!/bin/bash
here=$(realpath "$0")
here=$(dirname "$here")
cd "$here"
ARKCASE_VERSION="2021.03-RC11"
rm -rf artifacts
mkdir artifacts
echo "Downloading Arkcase core artifacts $ARKCASE_VERSION"
export ARKCASE_VERSION
aws s3 cp "s3://arkcase-container-artifacts/arkcase-core/${ARKCASE_VERSION}/artifacts/" artifacts/ --recursive

