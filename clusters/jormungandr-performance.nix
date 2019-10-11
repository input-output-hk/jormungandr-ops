{ tiny, large }:
let
  inherit (import ../nix { }) lib;
  inherit (lib) range listToAttrs mapAttrsToList nameValuePair foldl forEach;

  mkNode = { size ? tiny, role, ... }: {
    imports = [ size role ../modules/common.nix ];
  };

  mapNestedNodes = name:
    { amount ? null, ... }@args:
    (if amount != null then
      forEach (range 1 amount)
      (n: nameValuePair "${name}-${toString n}" (mkNode args))
    else
      nameValuePair name (mkNode args));

  mkNodes = defs:
    listToAttrs
    (foldl (sum: elem: sum ++ (if elem ? name then [ elem ] else elem)) [ ]
      (mapAttrsToList mapNestedNodes defs));

  nodes = mkNodes {
    monitor = {
      size = large;
      role = ../roles/monitor.nix;
    };

    explorer = {
      role = ../roles/jormungandr-explorer.nix;
    };

    faucet = {
      role = ../roles/jormungandr-faucet.nix;
    };

    stake = {
      amount = 1;
      role = ../roles/jormungandr-stake.nix;
    };

    relay = {
      amount = 1;
      role = ../roles/jormungandr-relay.nix;
    };
  };
in {
  network.description = "jormungandr-performance";
  network.enableRollback = true;
} // nodes
