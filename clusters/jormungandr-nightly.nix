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
      node.isRelay = true;
    }) {
      eu-central-1 = 3;
      ap-northeast-1 = 2;
      us-west-1 = 2;
    };

  nodes = mkNodes ({
    monitoring = {
      imports = [ large ../roles/monitor.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isMonitoring = true;
    };

    explorer = {
      imports = [ tiny ../roles/jormungandr-explorer.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isExplorer = true;
    };

    faucet = {
      imports = [ tiny ../roles/jormungandr-faucet.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isFaucet = true;
    };

    stake-euc1 = {
      amount = 3;
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
    };

    stake-apn1 = {
      amount = 2;
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
    };

    stake-usw1 = {
      amount = 2;
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
    };

  } // relays);
in {
  network.description = "Jormungandr Nightly";
  network.enableRollback = true;
} // nodes
