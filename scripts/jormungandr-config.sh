#!/usr/bin/env bash

node=$1

nixops ssh stake-euc1 -- <<'EOF'
start="$(systemctl cat jormungandr | grep -Po '(?<=ExecStart=)(\S+)')"
cfg="$(grep -Po '(\S+config\.yaml)' "$start")"
jq . "$cfg"
EOF
