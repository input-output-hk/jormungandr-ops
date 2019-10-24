{ targetEnv, tiny, large }:
let
  mkNodes = import ../nix/mk-nodes.nix { inherit targetEnv; };
  pkgs = import ../nix { };
  lib = pkgs.lib;

  nodes = mkNodes {
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

    jormungandr-faucet = {
      imports = [ tiny ../roles/jormungandr-faucet.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isFaucet = true;
    };

    stake-a = {
      amount = 13;
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
    };

    stake-b = {
      amount = 13;
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
    };

    stake-c = {
      amount = 13;
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
    };

    relay-a = {
      amount = 2;
      imports = [ tiny ../roles/jormungandr-relay.nix ];
      deployment.ec2.region = "us-west-1";
      node.isRelay = true;
    };

    relay-b = {
      amount = 2;
      imports = [ tiny ../roles/jormungandr-relay.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isRelay = true;
    };

    relay-c = {
      amount = 2;
      imports = [ tiny ../roles/jormungandr-relay.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isRelay = true;
    };
  };
in {
  network.description = "jormungandr-performance";
  network.enableRollback = true;
} // nodes
