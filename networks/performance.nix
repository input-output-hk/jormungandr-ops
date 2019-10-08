let
  inherit (import ../nix { }) lib;
  inherit (lib) range listToAttrs;

  faucet = n:
    { resources, pkgs, lib, ... }: {
      imports = [ ../physical/libvirtd/tiny.nix ../roles/jormungandr-faucet.nix ];
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../. + "/static/secrets/secret_pool_${toString n}.yaml";
        user = "jormungandr";
      };
    };

  relay = { resources, pkgs, lib, ... }: {
    imports = [ ../physical/libvirtd/tiny.nix ../roles/jormungandr-relay.nix ];
  };

  faucets = listToAttrs (map (n: {
    name = "faucet-${toString n}";
    value = faucet n;
  }) (range 1 2));

  relays = listToAttrs (map (n: {
    name = "relay-${toString n}";
    value = relay;
  }) (range 1 2));

in { network.description = "jo-perf"; } // faucets // relays
