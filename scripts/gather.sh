#!/usr/bin/env bash

set -e

# How long to run the test for
hours=1

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
    echo nixops ssh "$node" -- janalyze -x -j > "$dir/$node/janalyze/$now.json" &
  done

  wait
  sleep 10
done

echo "Finishing the test."

for node in "${nodes[@]}"; do
  echo nixops ssh "$node" -- journalctl -xb -u jormungandr > "$dir/$node/systemd.log" &
done

echo "Gathering systemd logs..."
wait

echo "Stopping nodes..."
for node in "${nodes[@]}"; do
  echo nixops ssh "$node" -- systemctl stop jormungandr &
done
sleep 10

for node in "${nodes[@]}"; do
  for f in blocks.sqlite blocks.sqlite-shm blocks.sqlite-wal; do
    echo nixops scp --from "$node" "/var/lib/jormungandr/$f" "$dir/$node/db/$f" &
  done
done

echo "Gathering dbs..."
wait

echo "Stats remain in $dir"

tar -OcvJ -C "$dir" . > "$report"
echo "Report stored in $report"

echo "Don't forget to destroy the cluster after you're done."
