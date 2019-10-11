{ globals, ... }:
let
  inherit (globals) cluster regions accessKeyId;
  inherit ((import ../nix { }).lib)
    nameValuePair mapAttrs' filterAttrs hasAttrByPath;

  nodes = filterAttrs
    (name: value: hasAttrByPath [ "deployment" "ec2" "region" ] value) cluster;

  settings = {
    require = [
      ../physical/aws/security-groups/allow-all.nix
      ../physical/aws/security-groups/allow-ssh.nix
      # ../physical/aws/security-groups/allow-deployer-ssh.nix
      ../physical/aws/security-groups/allow-monitoring-collection.nix
      ../physical/aws/security-groups/allow-public-www-https.nix
      ../physical/aws/security-groups/allow-jormungandr.nix
    ];

    resources.elasticIPs = mapAttrs' (name: node:
      nameValuePair "${name}-ip" {
        inherit accessKeyId;
        inherit (node.deployment.ec2) region;
      }) nodes;

    resources.ec2KeyPairs = __listToAttrs (map (region:
      nameValuePair "jormungandr-${region}" { inherit region accessKeyId; })
      regions);
  };
in cluster // settings
