{ lib, pkgs, config, resources, name, globals, ... }:
let inherit (config.node) fqdn;
  inherit (import ../nix {}) jormungandr-master;
  enableSSL = config.deployment.targetEnv != "libvirtd";
  protocol = if enableSSL then "https" else "http";

  registryFiles = __filterSource (path: type:
    (__match ''.*ed25519_(.*)\.(sig|json)$'' path) != null
  ) ../secrets/pools;
  registryZip = pkgs.runCommandNoCC "registry.zip" {
    buildInputs = with pkgs; [ zip ];
    inherit registryFiles;
  } ''
    dir=${globals.environment}-testnet-stakepool-registry-master/registry
    mkdir -p $dir
    cp $registryFiles/* $dir
    zip -r -9 $out $dir
  '';

  registryRoot = pkgs.runCommand "stakepool-registry" {} ''
    mkdir -p $out/stakepool-registry
    cp ${registryFiles}/* $out/stakepool-registry/
    cp ${registryZip} $out/stakepool-registry/registry.zip
  '';
in {
  imports = [ ./jormungandr-relay.nix ];

  node.fqdn = "${name}.${globals.domain}";

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
        https://shelley-testnet-explorer-${globals.environment}.netlify.com 1;
      }

      map $origin_allowed $origin {
        default "";
        1 $http_origin;
      }
    '';

    virtualHosts.${fqdn}.locations."/stakepool-registry" = {
      extraConfig = ''
        allow all;
        autoindex on;
        root ${registryRoot};
      '';
    };
  };

  #services.jormungandr.rest.cors.allowedOrigins = [ "https://shelley-testnet-explorer-qa.netlify.com" ];
}
