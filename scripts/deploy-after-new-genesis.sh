#!/usr/bin/env bash

set -ex

IFS=" " read -r -a relays <<< \
  "$(nix eval --raw '(toString (import ./scripts/nodes.nix).relaysNames)')"
IFS=" " read -r -a stakes <<< \
  "$(nix eval --raw '(toString (import ./scripts/nodes.nix).stakesNames)')"

nixops deploy --copy-only
nixops ssh-for-each -p --exclude monitoring -- 'systemctl stop jormungandr; rm -rf /var/lib/jormungandr'
nixops deploy --include monitoring
nixops deploy --include ${relays[*]}
nixops deploy --include ${stakes[*]}
