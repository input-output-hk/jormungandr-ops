{ tiny, xlarge }:
let
  inherit (import ../nix { }) lib;
  inherit (lib) range listToAttrs;

  mkBox = size: role: _: { imports = [ size role ]; };
  mkTiny = role: mkBox tiny role;
  mkXlarge = role: mkBox xlarge role;

  jormungandr-stake-pools = listToAttrs (map (n: {
    name = "stake-${toString n}";
    value = _: {
      imports = [ tiny ../roles/jormungandr-stake.nix ../modules/common.nix ];
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../. + "/static/secrets/secret_pool_${toString n}.yaml";
        user = "jormungandr";
      };
    };
  }) (range 1 1));

  jormungandr-relays = listToAttrs (map (n: {
    name = "relay-${toString n}";
    value = mkTiny ../roles/jormungandr-relay.nix;
  }) (range 1 1));

in {
  network.description = "jormungandr-performance";

  monitor = mkXlarge ../roles/monitor.nix;
  explorer = mkTiny ../roles/jormungandr-explorer.nix;
  faucet = mkTiny ../roles/jormungandr-faucet.nix;
} // jormungandr-stake-pools // jormungandr-relays
