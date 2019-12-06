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

    iohk1 = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/IOHK1-secret.yaml;
        user = "jormungandr";
      };
    };

    iohk2 = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/IOHK2-secret.yaml;
        user = "jormungandr";
      };
    };

    iohk3 = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/IOHK3-secret.yaml;
        user = "jormungandr";
      };
    };

    iohk4 = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/IOHK4-secret.yaml;
        user = "jormungandr";
      };
    };

    iohk5 = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/IOHK5-secret.yaml;
        user = "jormungandr";
      };
    };

    iohk6 = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/IOHK6-secret.yaml;
        user = "jormungandr";
      };
    };

    iohk7 = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/IOHK7-secret.yaml;
        user = "jormungandr";
      };
    };

    iohk8 = {
      imports = [ medium ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/IOHK8-secret.yaml;
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
