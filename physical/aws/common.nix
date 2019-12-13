{ pkgs ? import ../../nix { }, globals ? import ../../globals.nix, cluster, ... }:
let
  inherit (pkgs) lib;
  inherit (lib)
    attrValues foldl' mapAttrs' nameValuePair recursiveUpdate unique
    filterAttrs;
  inherit (globals.ec2.credentials) accessKeyId;

  nodes = filterAttrs (name: node:
    ((node.deployment.targetEnv or null) == "ec2")
    && ((node.deployment.ec2.region or null) != null)) cluster;

  regions = unique (map (node: node.deployment.ec2.region) (attrValues nodes));

  securityGroupFiles = let dir = ./security-groups;
  in map (n: dir + "/${n}") (__attrNames (builtins.readDir dir));

  importSecurityGroup = region: file:
    import file { inherit accessKeyId lib region nodes; };

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
        regions);
    };
  };
in cluster // settings
