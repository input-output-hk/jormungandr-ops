#!/usr/bin/env bash

set -ex

if [[ -z "$*" ]]; then
  IFS=" " read -r -a nodes <<< "$(nix eval --raw '((import ./scripts/nodes.nix).string)')"
else
  nodes=("$@")
fi

echo "deploying to: ${nodes[*]}"

length=${#nodes[@]}
current=0
time="$(date +%Y-%m-%d-%H-%M)"
dir="backup/$time"
mkdir -p "$dir"

heightOf() {
  node=$1
  nixops ssh "$node" -- 'jcli rest v0 node stats get --output-format json | jq -r .lastBlockHeight'
}

waitForSync() {
  node=$1
  height=$(heightOf "$node")
  stake="stake-apn1"
  if [[ $node = "$stake" ]]; then
    stake="stake-euc1"
  fi
  stakeHeight=$(heightOf $stake)

  until [[ $((stakeHeight - height)) -le 10 ]]; do
    echo -ne "\r$height/$stakeHeight Δ$((stakeHeight - height))"
    sleep 3
  done
}

deployJormungandr() {
  node=$1
  nixops ssh "$node" -- systemctl stop jormungandr
  sleep 5
  nixops ssh "$node" -- tar -OcvJ -C /var/lib/jormungandr . > "$dir/$node.tar.xz"
  nixops ssh "$node" -- rm -rf /var/lib/jormungandr
  nixops deploy --include "$node"
}

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
