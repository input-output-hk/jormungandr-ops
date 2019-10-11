{ lib, config, resources, ... }:
let
  inherit (config.node) fqdn;
in {
  imports = [ ./jormungandr-relay.nix ];

  deployment.ec2.securityGroups = [
    resources.ec2SecurityGroups."allow-public-www-https-${config.node.region}"
  ];

  services.jormungandr-explorer = {
    enable = true;
    virtualHost = "${fqdn}";
    enableSSL = false;
    jormungandrApi = "http://${fqdn}/explorer/graphql";
  };

  services.jormungandr.rest.cors.allowedOrigins = [ "http://${fqdn}" ];
}
