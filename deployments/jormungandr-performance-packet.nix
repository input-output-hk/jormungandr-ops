{ globals, ... }:
let
  inherit (globals.packet) credentials;

  cluster = import ../clusters/jormungandr-performance.nix {
    targetEnv = "packet";
    tiny = ../physical/packet/t1.small.nix;
    large = ../physical/packet/c1.small.nix;
  };

  lib = (import ../nix { }).lib;

  settings = {
    resources.packetKeyPairs.global = credentials;
    resources.route53RecordSets = lib.mapAttrs' (name: value: {
      name = "${name}-route53";
      value = { resources, ... }: {
        domainName = "${name}.${globals.domain}.";
        zoneName = "${globals.zone}.";
        recordValues = [ resources.machines.${name} ];
      };
    }) { # todo, need to use resources.machines
      monitor = 1;
      explorer = 1;
      faucet = 1;
    };
  };
in cluster // settings
