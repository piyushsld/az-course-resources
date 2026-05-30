#!/bin/bash

set -euxo pipefail

echo "Bootstrap started: $(date)"

apt-get update
mkdir actions-runner && cd actions-runner

curl -o actions-runner-linux-x64-2.334.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz
echo "048024cd2c848eb6f14d5646d56c13a4def2ae7ee3ad12122bee960c56f3d271  actions-runner-linux-x64-2.334.0.tar.gz" | shasum -a 256 -c

tar xzf ./actions-runner-linux-x64-2.334.0.tar.gz

./config.sh --url https://github.com/piyushsld/az-course-resources --token B6WPDUNM64MCMTPD7SI5WSTKDKU2U

sudo ./svc.sh install && sudo ./svc.sh start && sudo ./svc.sh status

echo "Bootstrap completed: $(date)"