{ targetEnv, t3a-large, t3-xlarge, t3-2xlarge }:
let
  mkNodes = import ../nix/mk-nodes.nix { inherit targetEnv; };
  pkgs = import ../nix { };
  lib = pkgs.lib;

  genericStakes = prefix: regions: let
    keyDir = ../secrets/pools-redist-mock2;
    allNames = __attrNames (__readDir keyDir);
    names = lib.filter (lib.hasPrefix "${prefix}-secret-") allNames;
    fileToNode = file:
      let
        name = lib.replaceStrings ["-secret-" ".yaml"] ["" ""] (lib.toLower file);
      in {
        inherit name;
        value = {
          imports = [ t3a-large ../roles/jormungandr-stake.nix ];
          deployment.ec2.region = regions.${name};
          node.isStake = true;
          node.dontGenerateKey = true;
          deployment.keys."secret_pool.yaml" = {
            keyFile = keyDir + "/${file}";
            user = "jormungandr";
          };
        };
      };
    in lib.listToAttrs (map fileToNode names);

  mkGenericStakes = prefix: regions:
    genericStakes prefix regions;

  mkStakes = region: amount: {
    inherit amount;
    imports = [ t3a-large ../roles/jormungandr-stake.nix ];
    deployment.ec2.region = region;
    node.isStake = true;
  };

  mkTrustedPoolPeers = region: amount: {
    inherit amount;
    imports = [ t3a-large ../roles/jormungandr-relay.nix ];
    deployment.ec2.region = region;
    node.isTrustedPoolPeer = true;
    # services.jormungandr.maxUnreachableNodes = lib.mkForce 0;
  };

  mkTrustedPeers = region: amount: {
    inherit amount;
    imports = [ t3a-large ../roles/jormungandr-daedalus-relay.nix ];
    deployment.ec2.region = region;
    node.isTrustedPeer = true;
  };

  mkRelays = region: amount: {
    inherit amount;
    imports = [ t3a-large ../roles/jormungandr-backup-relay.nix ];
    deployment.ec2.region = region;
    node.isRelay = true;
  };

  standardNodes = {
    monitoring = {
      imports = [ t3-xlarge ../roles/monitor.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isMonitoring = true;
    };

    explorer-api = {
      amount = 2;
      imports = [ t3-2xlarge ../roles/jormungandr-explorer-api.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isExplorerApi = true;
      systemd.services.jormungandr = {
        serviceConfig = {
          MemoryMax = lib.mkForce "20G";
          # Restart = lib.mkForce "no";
        };
      };
    };

    explorer = {
      imports = [ t3-2xlarge ../roles/jormungandr-explorer.nix ];
      systemd.services.jormungandr = {
        serviceConfig = {
          MemoryMax = lib.mkForce "20G";
          # Restart = lib.mkForce "no";
        };
      };
      deployment.ec2.region = "eu-central-1";
      node.isExplorer = true;
      node.isExplorerApi = true;
    };

    # US West (N. California)
    relay-a = mkTrustedPeers "us-west-1" 6;
    relay-a-backup = mkRelays "us-west-1" 1;
    relay-pools-a = mkTrustedPoolPeers "us-west-1" 3;

    # Asia Pacific (Tokyo)
    relay-b = mkTrustedPeers "ap-northeast-1" 6;
    relay-b-backup = mkRelays "ap-northeast-1" 1;
    relay-pools-b = mkTrustedPoolPeers "ap-northeast-1" 3;

    # EU (Frankfurt)
    relay-c = mkTrustedPeers "eu-central-1" 6;
    relay-c-backup = mkRelays "eu-central-1" 1;
    relay-pools-c = mkTrustedPoolPeers "eu-central-1" 3;

    # US East (N. Virginia)
    relay-d = mkTrustedPeers "us-east-1" 6;
    relay-d-backup = mkRelays "us-east-1" 1;

    # Asia Pacific (Singapore)
    relay-e = mkTrustedPeers "ap-southeast-1" 6;
    relay-e-backup = mkRelays "ap-southeast-1" 1;
  };

  bootstrapStakeNodes = {
    iohk1 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-1.yaml;
        user = "jormungandr";
      };
    };

    iohk2 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-2.yaml;
        user = "jormungandr";
      };
    };

    iohk3 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-3.yaml;
        user = "jormungandr";
      };
    };

    iohk4 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-4.yaml;
        user = "jormungandr";
      };
    };

    iohk5 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-5.yaml;
        user = "jormungandr";
      };
    };

    iohk6 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-6.yaml;
        user = "jormungandr";
      };
    };

    iohk7 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-7.yaml;
        user = "jormungandr";
      };
    };

    iohk8 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/iohk-secret-8.yaml;
        user = "jormungandr";
      };
    };

    priv1 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/priv-secret-1.yaml;
        user = "jormungandr";
      };
    };

    priv2 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/priv-secret-2.yaml;
        user = "jormungandr";
      };
    };

    priv3 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/priv-secret-3.yaml;
        user = "jormungandr";
      };
    };

    priv4 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "ap-northeast-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/priv-secret-4.yaml;
        user = "jormungandr";
      };
    };

    priv5 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "us-west-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/priv-secret-5.yaml;
        user = "jormungandr";
      };
    };

    priv6 = {
      imports = [ t3a-large ../roles/jormungandr-stake.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isStake = true;
      node.dontGenerateKey = true;
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../secrets/pools/priv-secret-6.yaml;
        user = "jormungandr";
      };
    };

  };

  #iohk-private = mkGenericStakes "iop" {
  #  iop01 = "eu-central-1";
  #  iop02 = "eu-central-1";
  #  iop03 = "eu-central-1";
  #  iop04 = "eu-central-1";
  #  iop05 = "eu-central-1";

  #  iop06 = "ap-northeast-1";
  #  iop07 = "ap-northeast-1";
  #  iop08 = "ap-northeast-1";
  #  iop09 = "ap-northeast-1";
  #  iop10 = "ap-northeast-1";

  #  iop11 = "us-west-1";
  #  iop12 = "us-west-1";
  #  iop13 = "us-west-1";
  #  iop14 = "us-west-1";
  #};

  #iohk-public = mkGenericStakes "ioh" {
  #  ioh10 = "eu-central-1";
  #  ioh11 = "eu-central-1";
  #  ioh41 = "eu-central-1";
  #  ioh42 = "eu-central-1";

  #  ioh81 = "ap-northeast-1";
  #  ioh82 = "ap-northeast-1";
  #  ioh83 = "ap-northeast-1";
  #  ioh84 = "ap-northeast-1";

  #  ioh85 = "us-west-1";
  #  ioh86 = "us-west-1";
  #  ioh87 = "us-west-1";
  #  ioh88 = "us-west-1";
  #  ioh89 = "us-west-1";
  #};

  nodes = mkNodes (
    standardNodes
    // bootstrapStakeNodes
    # // iohk-private
    # // iohk-public
  );

in {
  network.description = "Jormungandr Incentivized";
  network.enableRollback = pkgs.lib.traceValFn (x: if x then "Rollback enabled" else "Rollback DISABLED")
    (if (__getEnv "ROLLBACK_ENABLED") == "false" then false else true);
} // nodes
