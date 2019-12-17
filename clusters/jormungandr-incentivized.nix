{ targetEnv, tiny, large }:
let
  mkNodes = import ../nix/mk-nodes.nix { inherit targetEnv; };
  pkgs = import ../nix { };
  lib = pkgs.lib;

  mkStakes = region: amount: {
    inherit amount;
    imports = [ tiny ../roles/jormungandr-stake.nix ];
    deployment.ec2.region = region;
    node.isStake = true;
  };

  mkRelays = region: amount: {
    inherit amount;
    imports = [ tiny ../roles/jormungandr-relay.nix ];
    deployment.ec2.region = region;
    node.isTrustedPeer = true;
  };

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
      node.isRelay = true;
    };

    iohk1 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-1.yaml;
        user = "jormungandr";
      };
    };

    iohk2 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-2.yaml;
        user = "jormungandr";
      };
    };

    iohk3 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-3.yaml;
        user = "jormungandr";
      };
    };

    iohk4 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-4.yaml;
        user = "jormungandr";
      };
    };

    iohk5 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-5.yaml;
        user = "jormungandr";
      };
    };

    iohk6 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-6.yaml;
        user = "jormungandr";
      };
    };

    relay-a = mkRelays "us-west-1" 2;
    relay-b = mkRelays "ap-northeast-1" 2;
    relay-c = mkRelays "eu-central-1" 3;
  };
in {
  network.description = "Jormungandr Incentivized";
  network.enableRollback = true;
} // nodes
