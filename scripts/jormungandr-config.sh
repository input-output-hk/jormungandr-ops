#!/usr/bin/env bash

node=$1

nixops ssh "$node" -- <<'EOF'
start="$(systemctl cat jormungandr | grep -Po '(?<=ExecStart=)(\S+)')"
cfg="$(grep -Po '(\S+config\.yaml)' "$start")"
jq .storage "$cfg"
EOF
