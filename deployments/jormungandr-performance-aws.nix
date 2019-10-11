{globals, ...}:
let
  inherit (globals) regions accessKeyId;

  cluster = import ../clusters/jormungandr-performance.nix {
    tiny = ../physical/aws/t2.nano.nix;
    large = ../physical/aws/t3.xlarge.nix;
  };

  region = __head regions;

  settings = {
    require = [
      ../physical/aws/security-groups/allow-all.nix
      ../physical/aws/security-groups/allow-ssh.nix
      # ../physical/aws/security-groups/allow-deployer-ssh.nix
      ../physical/aws/security-groups/allow-monitoring-collection.nix
      ../physical/aws/security-groups/allow-public-www-https.nix
      ../physical/aws/security-groups/allow-jormungandr.nix
    ];

    resources.elasticIPs = __listToAttrs (map (name: {
      name = "${name}-ip";
      value = { inherit region accessKeyId; };
    }) (__attrNames cluster));

    resources.ec2KeyPairs = __listToAttrs (map (region:
      { name = "jormungandr-${region}"; value = { inherit region accessKeyId; }; }
    ) regions);
  };
in cluster // settings
