{ name, config, resources, lib, ... }:
let inherit (lib) mkDefault;
  inherit ( config.deployment.ec2 ) region;
in {
  deployment.targetEnv = "ec2";

  deployment.ec2 = {
    region = mkDefault "eu-central-1";

    keyPair = mkDefault
      resources.ec2KeyPairs."jormungandr-${region}";

    ebsInitialRootDiskSize = mkDefault 30;

    elasticIPv4 = resources.elastiIPs."${name}-ip" or "";

    securityGroups = [
      "allow-deployer-ssh-${region}"
      "allow-monitoring-collection-${region}"
    ];
  };

  networking.hostName = mkDefault
    "${config.deployment.name}.${config.deployment.targetEnv}.${name}";
}
