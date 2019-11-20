#!/bin/bash

set -eux pipefail

source git-kubo-ci/pks-pipelines/deploy-k8s/utils/all-env.sh

pushd git-pks-docker-bosh-release
  bosh create-release --version="${DOCKER_GIT_SHA}" --tarball pipeline.tgz
  bosh upload-release pipeline.tgz
popd
