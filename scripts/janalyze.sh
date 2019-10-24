#!/usr/bin/env bash

if [[ -z "$*" ]]; then
  IFS=" " read -r -a nodes <<< "$(nix eval --raw '((import ./scripts/nodes.nix).string)')"
else
  nodes=("$@")
fi

echo "gather analytics for ${nodes[*]}"

while true; do
  time="$(date --iso-8601=seconds)"
  dir="janalyze/$time"
  mkdir -p "$dir"

  for node in "${nodes[@]}"; do
    echo "checking $node"
    nixops ssh "$node" -- janalyze -x -j | jq . | tee "$dir/$node.json"
  done

  sleep 60
done

