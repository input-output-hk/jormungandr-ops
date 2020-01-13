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
      node.isExplorerApi = true;
    };

    #faucet = {
    #  imports = [ tiny ../roles/jormungandr-faucet.nix ];
    #  deployment.ec2.region = "eu-central-1";
    #  node.isFaucet = true;
    #};

    stake-a-1 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-1.yaml;
        user = "jormungandr";
      };
    };

    stake-a-2 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-2.yaml;
        user = "jormungandr";
      };
    };

    stake-b-1 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-3.yaml;
        user = "jormungandr";
      };
    };

    stake-b-2 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-4.yaml;
        user = "jormungandr";
      };
    };

    stake-c-1 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-5.yaml;
        user = "jormungandr";
      };
    };

    stake-c-2 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-6.yaml;
        user = "jormungandr";
      };
    };
    #stake-a = {
    #  amount = 3;
    #  imports = [ tiny ../roles/jormungandr-stake.nix ];
    #  deployment.ec2.region = "us-west-1";
    #  node.isStake = true;
    #};

    #stake-b = {
    #  amount = 2;
    #  imports = [ tiny ../roles/jormungandr-stake.nix ];
    #  deployment.ec2.region = "ap-northeast-1";
    #  node.isStake = true;
    #};

    #stake-c = {
    #  amount = 2;
    #  imports = [ tiny ../roles/jormungandr-stake.nix ];
    #  deployment.ec2.region = "eu-central-1";
    #  node.isStake = true;
    #};

    relay-a = {
      amount = 3;
      imports = [ tiny ../roles/jormungandr-relay.nix ];
      deployment.ec2.region = "us-west-1";
      node.isTrustedPeer = true;
    };

    relay-b = {
      amount = 2;
      imports = [ tiny ../roles/jormungandr-relay.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isTrustedPeer = true;
    };

    relay-c = {
      amount = 2;
      imports = [ tiny ../roles/jormungandr-relay.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isTrustedPeer = true;
    };

    qa = {
      amount = 1;
      imports = [
        tiny 
        ../roles/jormungandr-relay.nix
        ../roles/jormungandr-qa.nix
      ];
      deployment.ec2.region = "eu-central-1";
      node.isRelay = true;
    };
  };
in {
  network.description = "Jormungandr QA";
  network.enableRollback = true;
} // nodes
