{ targetEnv, tiny, large }:
let
  mkNodes = import ../nix/mk-nodes.nix { inherit targetEnv; };
  pkgs = import ../nix { };
  lib = pkgs.lib;

  relays = lib.mapAttrs' (region: amount:
    lib.nameValuePair "relay-${region}" {
      imports = [ tiny ../roles/jormungandr-relay.nix ];
      inherit amount;
      deployment.ec2.region = region;
    }) {
      eu-central-1 = 3;
      ap-northeast-1 = 2;
      us-west-1 = 2;
    };

  nodes = mkNodes ({
    monitoring = {
      imports = [ large ../roles/monitor.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    explorer = {
      imports = [ tiny ../roles/jormungandr-explorer.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    jormungandr-faucet = {
      imports = [ tiny ../roles/jormungandr-faucet.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    stake-euc1 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    stake-apn1 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      deployment.packet.facility = "ams1";
    };
  } // relays);
in {
  network.description = "jormungandr-testnet";
  network.enableRollback = true;
} // nodes
