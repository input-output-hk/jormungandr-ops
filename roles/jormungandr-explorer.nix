{ lib, pkgs, config, resources, name, globals, nodes, ... }:
let
  inherit (config.node) fqdn;
  inherit (lib) mapAttrs' filterAttrs mapAttrsToList;
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

  genesisRoot = pkgs.runCommand "genesis" {} ''
    mkdir -p $out/genesis
    cp ${../static/genesis.yaml} $out/genesis/genesis.yaml
  '';

  sources = import ../nix/sources.nix;
  jormungandrNix = import sources.jormungandr-nix {};

  genesis = __fromJSON (__readFile ../static/genesis.yaml);

  explorerFrontend = jormungandrNix.explorerFrontend {
    configJSON = __toFile "config.json" (__toJSON {
      explorerUrl = "${protocol}://${fqdn}/explorer/graphql";

      networkSettings = {
        genesisTimestamp = genesis.blockchain_configuration.block0_date;
        slotsPerEpoch = genesis.blockchain_configuration.slots_per_epoch;
        slotDuration = genesis.blockchain_configuration.slot_duration;
      };

      assuranceLevels = {
        low = 3;
        medium = 7;
        high = 9;
      };

      currency = {
        symbol = "ADA";
        decimals = 6;
      };
    });
  };

  explorerNodes = filterAttrs (_: node: node.config.node.isExplorerApi) nodes;
in {
  imports = [ ./jormungandr-explorer-api.nix ];

  node.fqdn = "${name}.${globals.domain}";

  deployment.ec2.securityGroups = [
    resources.ec2SecurityGroups."allow-public-www-https-${config.node.region}"
  ];

  systemd.services.jormungandr.after = [ "wg-quick-w0.service" ];

  networking.wg-quick.interfaces.wg0.peers = mapAttrsToList (nodeName: node:
    {
      allowedIPs = [ "${node.config.node.wireguardIP}/32" ];
      publicKey = lib.fileContents (../secrets/wireguard + "/${nodeName}.public");
      presharedKeyFile = "/run/keys/wg_shared";
      persistentKeepalive = 25;
    }
  ) explorerNodes;

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.jormungandr.enable = true;
  services.jormungandr.enableExplorer = true;

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    serverTokens = false;

    commonHttpConfig = ''
      log_format x-fwd '$remote_addr - $remote_user [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent" "$http_x_forwarded_for"';
      access_log syslog:server=unix:/dev/log x-fwd;

      map $http_origin $origin_allowed {
        default 0;
        https://shelleyexplorer.cardano.org 1;
        https://shelley-testnet-explorer-staging.netlify.com 1;
      }

      map $origin_allowed $origin {
        default "";
        1 $http_origin;
      }
    '';

    upstreams.jormungandr-explorer-api.servers = mapAttrs' (nodeName: node:
      {
        name = "${node.config.services.jormungandr.rest.listenAddress}";
        value = {};
      }
    ) explorerNodes;

    upstreams.jormungandr-reward-api.servers = mapAttrs' (nodeName: node:
      {
        name = "${node.config.services.jormungandr-reward-api.host}:${toString node.config.services.jormungandr-reward-api.port}";
        value = {};
      }
    ) explorerNodes;

    virtualHosts = {
      ${fqdn} = let
        headers = ''
          add_header 'Vary' 'Origin' always;
          add_header 'access-control-allow-origin' $origin always;
          add_header 'Access-Control-Allow-Methods' 'POST, OPTIONS, GET' always;
          add_header 'Access-Control-Allow-Headers' 'User-Agent,X-Requested-With,Content-Type' always;
        '';
      in {
        forceSSL = enableSSL;
        enableACME = enableSSL;

        locations = {
          "/" = {
            root = explorerFrontend;
            index = "index.html";
            tryFiles = "$uri $uri/ /index.html?$args";
          };

          "/explorer/graphql".extraConfig = ''
            if ($request_method = OPTIONS) {
              ${headers}
              add_header 'Access-Control-Max-Age' 1728000;
              add_header 'Content-Type' 'text/plain; charset=utf-8';
              add_header 'Content-Length' 0;
              return 204;
              break;
            }

            if ($request_method = POST) {
              ${headers}
            }

            proxy_pass http://jormungandr-explorer-api;
            proxy_set_header Host $host:$server_port;
            proxy_set_header X-Real-IP $remote_addr;
          '';

          "/api/rewards".extraConfig = ''
            if ($request_method = OPTIONS) {
              ${headers}
              add_header 'Access-Control-Max-Age' 1728000;
              add_header 'Content-Type' 'text/plain; charset=utf-8';
              add_header 'Content-Length' 0;
              return 204;
              break;
            }

            if ($request_method = GET) {
              ${headers}
            }

            proxy_pass http://jormungandr-reward-api/api/rewards;
            proxy_set_header Host $host:$server_port;
            proxy_set_header X-Real-IP $remote_addr;
          '';
          "/api/v0/settings".extraConfig = ''
            if ($request_method = OPTIONS) {
              ${headers}
              add_header 'Access-Control-Max-Age' 1728000;
              add_header 'Content-Type' 'text/plain; charset=utf-8';
              add_header 'Content-Length' 0;
              return 204;
              break;
            }

            if ($request_method = GET) {
              ${headers}
            }

            proxy_pass http://jormungandr-explorer-api;
            proxy_set_header Host $host:$server_port;
            proxy_set_header X-Real-IP $remote_addr;
          '';

          "/stakepool-registry".extraConfig = ''
            allow all;
            autoindex on;
            root ${registryRoot};
          '';

          "/genesis".extraConfig = ''
            allow all;
            autoindex on;
            root ${genesisRoot};
          '';
        };
      };
    };
  };

  #services.jormungandr.rest.cors.allowedOrigins = [ "https://shelley-testnet-explorer-qa.netlify.com" ];

  # services.jormungandr-explorer = {
  #   enable = true;
  #   virtualHost = "${fqdn}";
  #   inherit enableSSL;
  #   jormungandrApi = "${protocol}://${fqdn}/explorer/graphql";
  # };
}
