{ config, resources, name, ... }:
let sources = import ../nix/sources.nix;
    inherit (import ../globals.nix) domain;
in {
  imports =
    [ (sources.jormungandr-faucet + "/nix/nixos") ./jormungandr-relay.nix ];

  node.fqdn = "${name}.${domain}";

  deployment.keys."faucet.sk" = { keyFile = ../static/secrets/stake_1_key.sk; };

  deployment.ec2.securityGroups = [
    resources.ec2SecurityGroups."allow-public-www-https-${config.node.region}"
  ];

  services.jormungandr-faucet = {
    enable = true;
    lovelacesToGive = 10000000000;
    jormungandrApi =
      "http://${config.services.jormungandr.rest.listenAddress}/api/v0";
    secondsBetweenRequests = 30;
    secretKeyPath = "/run/keys/faucet.sk";
  };

  systemd.services."jormungandr-faucet" = {
    after = [ "faucet.sk-key.service" ];
    wants = [ "faucet.sk-key.service" ];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

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
      limit_req_zone $binary_remote_addr zone=faucetPerIP:100m rate=1r/s;

      map $http_origin $origin_allowed {
        default 0;
        https://webdevc.iohk.io 1;
        https://testnet.iohkdev.io 1;
        http://127.0.0.1:4000 1;
      }

      map $origin_allowed $origin {
        default "";
        1 $http_origin;
      }
    '';

    virtualHosts = {
      "jormungandr-faucet.${domain}" = {
        forceSSL = config.deployment.targetEnv != "libvirtd";
        enableACME = config.deployment.targetEnv != "libvirtd";

        locations."/" = {
          extraConfig = let
            headers = ''
              add_header 'Vary' 'Origin' always;
              add_header 'Access-Control-Allow-Origin' $origin always;
              add_header 'Access-Control-Allow-Methods' 'POST, OPTIONS always';
              add_header 'Access-Control-Allow-Headers' 'User-Agent,X-Requested-With,Content-Type' always;
            '';
          in ''
            limit_req zone=faucetPerIP;

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

            proxy_pass http://127.0.0.1:${
              toString config.services.jormungandr-faucet.port
            };
            proxy_set_header Host $host:$server_port;
            proxy_set_header X-Real-IP $remote_addr;
          '';
        };
      };
    };
  };
}
