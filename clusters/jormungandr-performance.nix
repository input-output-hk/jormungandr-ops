{ targetEnv, tiny, medium, large }:
let
  mkNodes = import ../nix/mk-nodes.nix { inherit targetEnv; };
  pkgs = import ../nix { };
  lib = pkgs.lib;

  mkStakes = region: amount: {
    inherit amount;
    imports = [ medium ../roles/jormungandr-stake.nix ];
    deployment.ec2.region = region;
    node.isStake = true;
  };

  mkRelays = region: amount: {
    inherit amount;
    imports = [ medium ../roles/jormungandr-relay.nix ];
    deployment.ec2.region = region;
    node.isRelay = true;
  };

  nodes = mkNodes {
    monitoring = {
      imports = [ large ../roles/monitor.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isMonitoring = true;
    };

    explorer = {
      imports = [ medium ../roles/jormungandr-explorer.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isExplorer = true;
      node.isRelay = true;
    };

    faucet = {
      imports = [ medium ../roles/jormungandr-faucet.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isFaucet = true;
      node.isRelay = true;
    };

    stake-a = mkStakes "us-west-1" 333;
    stake-b = mkStakes "ap-northeast-1" 333;
    stake-c = mkStakes "eu-central-1" 334;

    relay-a = mkRelays "us-west-1" 2;
    relay-b = mkRelays "ap-northeast-1" 2;
    relay-c = mkRelays "eu-central-1" 2;
  };
in {
  network.description = "Jormungandr Performance";
  network.enableRollback = true;
} // nodes
