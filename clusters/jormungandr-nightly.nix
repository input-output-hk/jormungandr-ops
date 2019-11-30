{ targetEnv, large, xlarge, xlarge-monitor }:
let
  mkNodes = import ../nix/mk-nodes.nix { inherit targetEnv; };
  pkgs = import ../nix { };
  lib = pkgs.lib;

  relays = lib.mapAttrs' (region: amount:
    lib.nameValuePair "relay-${region}" {
      imports = [ large ../roles/jormungandr-relay.nix ];
      inherit amount;
      deployment.ec2.region = region;
      node.isRelay = true;
    }) {
      eu-central-1 = 3;
      ap-northeast-1 = 2;
      us-west-1 = 2;
    };

  nodes = mkNodes ({
    monitoring = {
      imports = [ xlarge-monitor ../roles/monitor.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isMonitoring = true;
    };

    explorer = {
      imports = [ xlarge ../roles/jormungandr-explorer.nix ];
      deployment.ec2 = {
        region = "eu-central-1";
        ebsInitialRootDiskSize = lib.mkForce 30;
      };
      node.isExplorer = true;
    };

    faucet = {
      imports = [ large ../roles/jormungandr-faucet.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isFaucet = true;
    };

    stake-euc1 = {
      amount = 3;
      imports = [ large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
    };

    stake-apn1 = {
      amount = 2;
      imports = [ large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
    };

    stake-usw1 = {
      amount = 2;
      imports = [ large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
    };

  } // relays);
in {
  network.description = "Jormungandr Nightly";
  network.enableRollback = true;
} // nodes
