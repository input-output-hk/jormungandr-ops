#!/usr/bin/env bash

# set -e

if [[ -z "$*" ]]; then
  IFS=" " read -r -a nodes <<< "$(nix eval --raw '((import ./scripts/nodes.nix).string)')"
else
  nodes=("$@")
fi

IFS=" " read -r -a stakes <<< "$(nix eval --raw '((import ./scripts/nodes.nix).stakeStrings)')"
length=${#nodes[@]}
time="$(date +%Y-%m-%d-%H-%M)"
dir="backup/$time"

backupJormungandr() {
  node=$1

  echo "$node backup start"

  mkdir -p "$dir"

  nixops ssh "$node" -- systemctl stop jormungandr

  sleep 5

  if nixops ssh "$node" -- "ls /var/lib/jormungandr" > /dev/null; then
    nixops ssh "$node" -- tar -OcJ -C /var/lib/jormungandr . > "$dir/$node.tar.xz"
  fi

  echo "$node backup done"
}

for node in "${nodes[@]}"; do
  if [[ $node = "monitoring" ]]; then
    echo "skipping monitoring"
  else
    backupJormungandr "$node" &
  fi
done

wait

echo "done."
