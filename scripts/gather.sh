#!/usr/bin/env bash

set -e

# How long to run the test for
hours=2

IFS=" " read -r -a nodes <<< "$(nix eval --raw '((import ./scripts/nodes.nix).string)')"

seconds=$((hours * 60 * 60))
from_time="$(date +%s)"
to_time="$((from_time + seconds))"
from_date="$(date --iso-8601=minutes)"
stats_dir="$PWD/stats"
dir="$stats_dir/$from_date"
report="$dir.tar.xz"

for node in "${nodes[@]}"; do
  mkdir -p "$dir/$node/db" "$dir/$node/janalyze"
done

cp -r static/ "$dir/chain_configuration"

echo "Stats will be stored in $dir."
echo "Gathering janalyze stats..."

while [[ $(date +%s) -lt $to_time ]]; do
  now="$(date --iso-8601=seconds)"
  printf "\r%02d minutes remaining..." "$(((to_time - $(date +%s)) / 60))"

  for node in "${nodes[@]}"; do
    nixops ssh "$node" -- janalyze -x -j > "$dir/$node/janalyze/$now.json" &
  done

  wait
  sleep 10
done

for node in "${nodes[@]}"; do
  nixops ssh "$node" -- systemctl stop jormungandr &
done

echo "Stopping Jormungandr..."
wait
sleep 10

for node in "${nodes[@]}"; do
  nixops ssh "$node" -- journalctl -xb -u jormungandr > "$dir/$node/systemd.log" &
done

echo "Gathering systemd logs..."
wait

for node in "${nodes[@]}"; do
  for f in blocks.sqlite blocks.sqlite-shm blocks.sqlite-wal; do
    nixops scp --from "$node" "/var/lib/jormungandr/$f" "$dir/$node/db/$f" &
  done
done

echo "Gathering dbs..."
wait

echo "Stats remain in $dir"

tar -OcvJ -C "$dir" . > "$report"
echo "Report stored in $report"

echo "Don't forget to destroy the monitoring after you're done."

# nixops destroy --confirm --include "${nodes[@]}"
