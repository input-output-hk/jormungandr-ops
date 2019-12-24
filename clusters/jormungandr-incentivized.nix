{ targetEnv, tiny, large }:
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
          imports = [ tiny ../roles/jormungandr-stake.nix ];
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
    imports = [ tiny ../roles/jormungandr-stake.nix ];
    deployment.ec2.region = region;
    node.isStake = true;
  };

  mkTrustedPoolPeers = region: amount: {
    inherit amount;
    imports = [ tiny ../roles/jormungandr-relay.nix ];
    deployment.ec2.region = region;
    node.isTrustedPoolPeer = true;
    services.jormungandr.maxUnreachableNodes = lib.mkForce 0;
  };

  mkTrustedPeers = region: amount: {
    inherit amount;
    imports = [ tiny ../roles/jormungandr-relay.nix ];
    deployment.ec2.region = region;
    node.isTrustedPeer = true;
  };

  mkRelays = region: amount: {
    inherit amount;
    imports = [ tiny ../roles/jormungandr-relay.nix ];
    deployment.ec2.region = region;
    node.isRelay = true;
  };

  standardNodes = {
    monitoring = {
      imports = [ large ../roles/monitor.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isMonitoring = true;
    };

    explorer-api = {
      amount = 2;
      imports = [ tiny ../roles/jormungandr-explorer-api.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isExplorerApi = true;
    };

    explorer = {
      imports = [ tiny ../roles/jormungandr-explorer.nix ];
      deployment.ec2.region = "eu-central-1";
      node.isExplorer = true;
      node.isExplorerApi = true;
    };

    relay-a = mkTrustedPeers "us-west-1" 3;
    relay-a-backup = mkRelays "us-west-1" 1;

    relay-b = mkTrustedPeers "ap-northeast-1" 3;
    relay-b-backup = mkRelays "ap-northeast-1" 1;

    relay-c = mkTrustedPeers "eu-central-1" 3;
    relay-c-backup = mkRelays "eu-central-1" 1;

    relay-pools-a = mkTrustedPoolPeers "us-west-1" 3;
    relay-pools-b = mkTrustedPoolPeers "ap-northeast-1" 3;
    relay-pools-c = mkTrustedPoolPeers "eu-central-1" 3;
  };

  bootstrapStakeNodes = {
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
  };

  iohk-private = mkGenericStakes "iop" {
    iop01 = "eu-central-1";
    iop02 = "eu-central-1";
    iop03 = "eu-central-1";
    iop04 = "eu-central-1";
    iop05 = "eu-central-1";

    iop06 = "ap-northeast-1";
    iop07 = "ap-northeast-1";
    iop08 = "ap-northeast-1";
    iop09 = "ap-northeast-1";
    iop10 = "ap-northeast-1";

    iop11 = "us-west-1";
    iop12 = "us-west-1";
    iop13 = "us-west-1";
    iop14 = "us-west-1";
  };

  iohk-public = mkGenericStakes "ioh" {
    ioh10 = "eu-central-1";
    ioh11 = "eu-central-1";
    ioh41 = "eu-central-1";
    ioh42 = "eu-central-1";

    ioh81 = "ap-northeast-1";
    ioh82 = "ap-northeast-1";
    ioh83 = "ap-northeast-1";
    ioh84 = "ap-northeast-1";

    ioh85 = "us-west-1";
    ioh86 = "us-west-1";
    ioh87 = "us-west-1";
    ioh88 = "us-west-1";
    ioh89 = "us-west-1";
  };

  nodes = mkNodes (
    standardNodes
    // bootstrapStakeNodes
    # // iohk-private
    # // iohk-public
  );

in {
  network.description = "Jormungandr Incentivized";
  network.enableRollback = true;
} // nodes
