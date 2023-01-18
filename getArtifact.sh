#!/bin/bash
here=$(realpath "$0")
here=$(dirname "$here")
ARKCASE_VERSION=2021.03-RC11
cd "$here"
echo "Downloading Arkcase core artifacts $ARKCASE_VERSION"
mkdir -p ../artifacts_ark_arkcase_core
aws s3 cp "s3://arkcase-container-artifacts/arkcase-core/${ARKCASE_VERSION}/artifacts/" ../artifacts_ark_arkcase_core// --recursive --profile FedRAMP-SSO

