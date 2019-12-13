{ lib ? import ../nix { }, globals ? import ../globals.nix, cluster, ... }:
let
  inherit (lib)
    attrValues foldl' mapAttrs' nameValuePair recursiveUpdate unique
    filterAttrs;
  inherit (globals.ec2.credentials) accessKeyId;

  nodes = filterAttrs (name: node:
    ((node.deployment.targetEnv or null) == "ec2")
    && ((node.deployment.ec2.region or null) != null)) cluster;

  regions = unique (map (node: node.deployment.ec2.region) (attrValues nodes));

  securityGroupFiles = [
    ./security-groups/allow-all.nix
    ./security-groups/allow-deployer-ssh.nix
    ./security-groups/allow-monitoring-collection.nix
    ./security-groups/allow-public-www-https.nix
    ./security-groups/allow-jormungandr.nix
    ./security-groups/allow-graylog-nodes.nix
  ];

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
