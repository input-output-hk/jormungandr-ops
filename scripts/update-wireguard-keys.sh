#!/usr/bin/env nix-shell
#! nix-shell -p wireguard -i bash

IFS=" " read -r -a nodes <<< "$(nix eval --raw '((import ./scripts/nodes.nix).allStrings)')"

keydir=secrets/wireguard
mkdir -p $keydir

current=1

wg genkey | tee "$keydir/shared.private" | wg pubkey > "$keydir/shared.public"

for node in "${nodes[@]}"; do
  wg genkey | tee "$keydir/$node.private" | wg pubkey > "$keydir/$node.public"
  echo "10.90.$((current / 256)).$((current % 256))" > "$keydir/$node.ip"

  current=$((current + 1))
done
