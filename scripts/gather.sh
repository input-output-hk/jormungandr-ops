#!/usr/bin/env bash

# nixops ssh-for-each

nodes="$(nix eval --raw "$(cat <<NIX
(toString
  (builtins.attrNames
    (builtins.removeAttrs
      ((import ./deployments/jormungandr-performance-packet.nix) { globals = import ./globals.nix; })
      [ "resources" "monitor" "network" ])))
NIX
)")"

time="$(date +%Y-%d-%m-%H-%M)"
statdir="$PWD/stats/$time"
mkdir -p $statdir

echo "stats will be stored in $statdir"
echo "gathering logs..."

for node in $nodes; do
  (
    nixops ssh "$node" -- journalctl -xe -u jormungandr > "$statdir/$node.systemd.log"
    nixops ssh "$node" -- janalyze -a 100 > "$statdir/$node.janalyze.aggregate.log"
    nixops ssh "$node" -- janalyze -b > "$statdir/$node.janalyze.bigvaluesort.log"
    nixops ssh "$node" -- janalyze -d > "$statdir/$node.janalyze.distribution.log"
    nixops ssh "$node" -- janalyze -f > "$statdir/$node.janalyze.full.log"
    nixops ssh "$node" -- janalyze -s > "$statdir/$node.janalyze.stats.log"
    nixops ssh "$node" -- janalyze -x > "$statdir/$node.janalyze.crossref.log"
  ) &
done

echo "waiting for log extraction to finish..."
wait

echo "stopping nodes..."
nixops ssh-for-each -p --exclude resources monitor network -- systemctl stop jormungandr

echo "gathering dbs..."
for node in $nodes; do
  nixops scp --from "$node" /var/lib/jormungandr/blocks.sqlite "$statdir/$node.sqlite" &
done

echo "waiting for db extraction to finish..."
wait

echo "stats remain in $statdir"

statsZip="$PWD/stats/$time-stats.zip"
zip -r -9 "$statsZip" "$statdir"
echo "logs and dbs stored in $statsZip"

chainZip="$PWD/stats/$time-chain.zip"
zip -r -9 "$chainZip" static
echo "blockchain config stored in $chainZip"
