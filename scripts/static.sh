#!/usr/bin/env bash

dir="$*"

rm -rf $dir

nix-shell ../jormungandr-nix/shell.nix \
  -A bootstrap \
  --arg customConfig "{ faucetAmounts = [ 1000000000 2000000000 ]; numberOfStakePools = 2; slots_per_epoch = 21600; slot_duration = 20; consensus_genesis_praos_active_slot_coeff = 0.2; kes_update_speed = 86400; rootDir = \"$dir\"; numberOfLeaders = 2; }" \
  --run 'echo done'
