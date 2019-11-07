#!/usr/bin/env bash

set -e

usage () {
  echo "usage: $0 [--force] [node1 node2 ...]" >&2
  exit 2
}

force=no

while getopts ":-:" optchar; do
  case "${optchar}" in
    -)
      case "${OPTARG}" in
        force) force=yes ;;
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

echo "deploying to: ${nodes[*]}"

IFS=" " read -r -a stakes <<< "$(nix eval --raw '((import ./scripts/nodes.nix).stakeStrings)')"
length=${#nodes[@]}
current=0
time="$(date +%Y-%m-%d-%H-%M)"
dir="backup/$time"

heightOf() {
  node=$1
  nixops ssh "$node" -- "sqlite3 --readonly /var/lib/jormungandr/blocks.sqlite 'select depth from BlockInfo order by depth desc limit 1;' || echo 0"
}

waitForSync() {
  node=$1

  height=$(heightOf "$node")
  stake="${stakes[0]}"
  if [[ $node = "$stake" ]]; then
    stake="${stakes[1]}"
  fi
  stakeHeight=$(heightOf $stake)

  until [[ $((stakeHeight - height)) -le 100 ]]; do
    printf "\r%d/%d  Δ%d " "$height" "$stakeHeight" "$((stakeHeight - height))"

    sleep 3

    height=$(heightOf "$node")
    stakeHeight=$(heightOf $stake)
  done

  echo " done."
}

deployJormungandr() {
  node=$1

  echo "deploying $node"

  mkdir -p "$dir"

  nixops ssh "$node" -- systemctl stop jormungandr

  sleep 5

  if nixops ssh "$node" -- "ls /var/lib/jormungandr" > /dev/null; then
    nixops ssh "$node" -- tar -OcJ -C /var/lib/jormungandr . > "$dir/$node.tar.xz"
  fi

  if [[ $force = "yes" ]]; then
    nixops ssh "$node" -- rm -rf /var/lib/jormungandr
  fi

  nixops deploy --include "$node"
}

nixops deploy --copy-only

for node in "${nodes[@]}"; do
  current=$((current + 1))

  if [[ $node = "monitoring" ]]; then
    nixops deploy --include "$node"
  else
    deployJormungandr "$node"

    if [[ "$current" -eq "$length" ]]; then
      echo "done."
    else
      waitForSync "$node"
    fi
  fi
done
