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
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    serverTokens = false;

    commonHttpConfig = ''
      map $http_origin $origin_allowed {
        default 0;
        https://shelley-testnet-explorer-qa.netlify.com 1;
      }

      map $origin_allowed $origin {
        default "";
        1 $http_origin;
      }
    '';
  };

  #services.jormungandr.rest.cors.allowedOrigins = [ "https://shelley-testnet-explorer-qa.netlify.com" ];
}
