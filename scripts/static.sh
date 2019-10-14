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
{
  numberOfStakePools = 48;
  slots_per_epoch = 21600;
  slot_duration = 20;
  consensus_genesis_praos_active_slot_coeff = 0.2;
  kes_update_speed = 86400;
  rootDir = "$dir";
  numberOfLeaders = 48;
}
CONFIG
)"
