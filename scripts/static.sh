#!/usr/bin/env bash

set -ex

dir=./static

if [ -d "$dir" ]; then
    rm -rf "$dir"
fi

nix-shell ../jormungandr-nix2/shell.nix \
-A bootstrap \
--run 'echo done' \
--arg customConfig "$(cat <<CONFIG
rec {
  consensus_genesis_praos_active_slot_coeff = 0.1;
  faucetAmount = 100000000000000 / numberOfStakePools;
  kes_update_speed = 86400;
  block0_date = $(date +%s);
  linear_fees_certificate = 10000;
  linear_fees_coefficient = 50;
  linear_fees_constant = 1000;
  numberOfLeaders = numberOfStakePools;
  numberOfStakePools = __length (__attrNames (import ./scripts/nodes.nix).stakes);
  rootDir = "$dir";
  slot_duration = 2;
  slots_per_epoch = 7200;
}
CONFIG
)"
