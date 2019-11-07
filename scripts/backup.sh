#!/usr/bin/env bash

set -e

usage () {
  echo "usage: $0 [node1 node2 ...]" >&2
  exit 2
}

while getopts ":-:" optchar; do
  case "${optchar}" in
    -)
      case "${OPTARG}" in
        *) usage ;;
      esac ;;
    *) usage ;;
  esac
done

if [[ -z "$*" ]]; then
  IFS=" " read -r -a nodes <<< "$(nix eval --raw '((import ./scripts/nodes.nix).string)')"
else
  nodes=("$@")
fi

IFS=" " read -r -a stakes <<< "$(nix eval --raw '((import ./scripts/nodes.nix).stakeStrings)')"
length=${#nodes[@]}
current=0
time="$(date +%Y-%m-%d-%H-%M)"
dir="backup/$time"

backupJormungandr() {
  node=$1

  echo "backing up $node"

  mkdir -p "$dir"

  nixops ssh "$node" -- systemctl stop jormungandr

  sleep 5

  if nixops ssh "$node" -- "ls /var/lib/jormungandr" > /dev/null; then
    nixops ssh "$node" -- tar -OcJ -C /var/lib/jormungandr . > "$dir/$node.tar.xz"
  fi
}

for node in "${nodes[@]}"; do
  current=$((current + 1))

  if [[ $node = "monitoring" ]]; then
    echo "skipping monitoring"
  else
    backupJormungandr "$node"

    if [[ "$current" -eq "$length" ]]; then
      echo "done."
    fi
  fi
done
