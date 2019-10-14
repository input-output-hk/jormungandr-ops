{ globals, ... }:
let
  inherit (globals.ec2) credentials;
  inherit (credentials) accessKeyId;
  pkgs = import ../nix { };
  inherit (pkgs.packages) pp;
  inherit (pkgs.lib)
    attrValues filter filterAttrs flatten foldl' hasAttrByPath listToAttrs
    mapAttrs' nameValuePair recursiveUpdate unique;

  cluster = import ../clusters/jormungandr-performance.nix {
    targetEnv = "ec2";
    tiny = ../physical/aws/t2.nano.nix;
    large = ../physical/aws/t3.xlarge.nix;
  };

  nodes = filterAttrs (name: node:
    ((node.deployment.targetEnv or null) == "ec2")
    && ((node.deployment.ec2.region or null) != null)) (pp cluster);

  regions =
    unique (map (node: node.deployment.ec2.region) (attrValues (pp nodes)));

  securityGroupFiles = [
    ../physical/aws/security-groups/allow-all.nix
    ../physical/aws/security-groups/allow-ssh.nix
    # ../physical/aws/security-groups/allow-deployer-ssh.nix
    ../physical/aws/security-groups/allow-monitoring-collection.nix
    ../physical/aws/security-groups/allow-public-www-https.nix
    ../physical/aws/security-groups/allow-jormungandr.nix
  ];

  importSecurityGroup = region: file:
    import file { inherit region accessKeyId; };

  mkEC2SecurityGroup = region:
    foldl' recursiveUpdate { }
    (map (importSecurityGroup region) securityGroupFiles);

  settings = {
    resources = {
      ec2SecurityGroups =
        foldl' recursiveUpdate { } (map mkEC2SecurityGroup regions);

      elasticIPs = mapAttrs' (name: node:
        nameValuePair "${name}-ip" {
          inherit accessKeyId;
          inherit (node.deployment.ec2) region;
        }) nodes;

      ec2KeyPairs = __listToAttrs (map (region:
        nameValuePair "jormungandr-${region}" { inherit region accessKeyId; })
        (pp regions));
    };
  };
in cluster // settings
