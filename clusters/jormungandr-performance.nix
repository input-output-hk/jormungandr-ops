{ targetEnv, tiny, large }:
let
  mkNodes = import ../nix/mk-nodes.nix { inherit targetEnv; };
  pkgs = import ../nix { };
  lib = pkgs.lib;

  nodes = mkNodes {
    monitoring = {
      imports = [ large ../roles/monitor.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
      node.isMonitoring = true;
    };

    explorer = {
      imports = [ tiny ../roles/jormungandr-explorer.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
      node.isExplorer = true;
    };

    jormungandr-faucet = {
      imports = [ tiny ../roles/jormungandr-faucet.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
      node.isFaucet = true;
    };

    stake-ams1 = {
      amount = 40;
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
      node.isStake = true;
    };

    relay-ams1 = {
      amount = 10;
      imports = [ tiny ../roles/jormungandr-relay.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
      node.isRelay = true;
    };
  };
in {
  network.description = "jormungandr-performance";
  network.enableRollback = true;
} // nodes
