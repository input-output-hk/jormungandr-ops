#!/usr/bin/env bash

set -ex

dir=./static

if [ -d "$dir" ]; then
    rm -rf "$dir"
fi

nix-shell ../jormungandr-nix/shell.nix \
-A bootstrap \
--run 'echo done' \
--arg customConfig "$(cat <<CONFIG
rec {
  consensus_genesis_praos_active_slot_coeff = 0.2;
  faucetAmount = 1000000000000 / numberOfStakePools;
  kes_update_speed = 1800;
  linear_fees_certificate = 10000;
  linear_fees_coefficient = 50;
  linear_fees_constant = 1000;
  numberOfLeaders = numberOfStakePools;
  numberOfStakePools = __length (__attrNames (import ./scripts/nodes.nix).stakes);
  rootDir = "$dir";
  slot_duration = 2;
  slots_per_epoch = 150;
}
CONFIG
)"
