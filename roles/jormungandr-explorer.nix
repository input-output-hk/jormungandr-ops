{ lib, config, resources, name, ... }:
let inherit (config.node) fqdn;
  enableSSL = config.deployment.targetEnv != "libvirtd";
  protocol = if enableSSL then "https" else "http";
  inherit (import ../globals.nix) domain;
in {
  imports = [ ./jormungandr-relay.nix ];

  node.fqdn = "${name}.${domain}";

  deployment.ec2.securityGroups = [
    resources.ec2SecurityGroups."allow-public-www-https-${config.node.region}"
  ];

  services.jormungandr-explorer = {
    enable = true;
    virtualHost = "${fqdn}";
    inherit enableSSL;
    jormungandrApi = "${protocol}://${fqdn}/explorer/graphql";
  };

  services.jormungandr.rest.cors.allowedOrigins = [ "${protocol}://${fqdn}" ];
}
