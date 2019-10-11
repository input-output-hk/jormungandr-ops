#!/usr/bin/env bash

set -euxo pipefail

# NixOps setup

export NIXOPS_DEPLOYMENT=jormungandr-performance-aws

nixops destroy || true
nixops delete || true
nixops create ./deployments/jormungandr-performance-aws.nix -I nixpkgs=./nix
nixops set-args --arg globals 'import ./globals.nix'
nixops deploy
