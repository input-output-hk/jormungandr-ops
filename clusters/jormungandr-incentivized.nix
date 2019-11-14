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

    iohk = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/iohk/iohk-secret.yaml;
        user = "jormungandr";
      };
    };

    emurgo = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/emurgo/emurgo-secret.yaml;
        user = "jormungandr";
      };
    };

    cf = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/cf/cf-secret.yaml;
        user = "jormungandr";
      };
    };

    #faucet = {
    #  imports = [ medium ../roles/jormungandr-faucet.nix ];
    #  deployment.ec2.region = "eu-central-1";
    #  node.isFaucet = true;
    #  node.isRelay = true;
    #};

    relay-a = mkRelays "us-west-1" 2;
    relay-b = mkRelays "ap-northeast-1" 2;
    relay-c = mkRelays "eu-central-1" 3;
  };
in {
  network.description = "Jormungandr Incentivized";
  network.enableRollback = true;
} // nodes
