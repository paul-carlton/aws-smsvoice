#!/bin/bash

set -euxo pipefail

export VERSION=0.0.1

# Build the example-prog and the test images
make ci-check

# Run the functional tests
ci/run_tests.sh
