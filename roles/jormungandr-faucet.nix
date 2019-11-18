{ config, resources, name, ... }:
let sources = import ../nix/sources.nix;
    inherit (import ../globals.nix) domain;
    ada = lovelace: lovelace * 1000000;
    leaderKeyNum = 1;
in {
  imports = [
    (sources.jormungandr-faucet + "/nix/nixos")
    (sources.jormungandr-nix + "/nixos")
    ./jormungandr-relay.nix
  ];


  node.fqdn = "${name}.${domain}";

  deployment.keys."faucet.sk" = {
    keyFile = ../. + "/static/leader_${toString leaderKeyNum}_key.sk";
  };

  deployment.ec2.securityGroups = [
    resources.ec2SecurityGroups."allow-public-www-https-${config.node.region}"
  ];

  services.jormungandr-monitor = {
    genesisAddrSelector = leaderKeyNum;
  };

  services.jormungandr-faucet = {
    enable = true;
    lovelacesToGive = ada 10000;
    jormungandrApi = "http://${config.services.jormungandr.rest.listenAddress}/api";
    secondsBetweenRequests = 30;
    secretKeyPath = "/run/keys/faucet.sk";
    jormungandrCliPackage = config.services.jormungandr.jcliPackage;
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
    mapHashBucketSize = 128;

    commonHttpConfig = ''
      log_format x-fwd '$remote_addr - $remote_user [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent" "$http_x_forwarded_for"';
      access_log syslog:server=unix:/dev/log x-fwd;
      limit_req_zone $binary_remote_addr zone=faucetPerIP:100m rate=1r/s;
      limit_req_status 429;
      server_names_hash_bucket_size 128;

      map $http_origin $origin_allowed {
        default 0;
        https://webdevc.iohk.io 1;
        http://webdevc.iohk.io 1;
        https://webdevr.iohk.io 1;
        http://webdevr.iohk.io 1;
        https://testnet.iohkdev.io 1;
        http://127.0.0.1:4000 1;
      }

      map $origin_allowed $origin {
        default "";
        1 $http_origin;
      }
    '';

    virtualHosts = {
      "${name}.${domain}" = {
        forceSSL = config.deployment.targetEnv != "libvirtd";
        enableACME = config.deployment.targetEnv != "libvirtd";

        locations."/" = {
          extraConfig = let
            headers = ''
              add_header 'Vary' 'Origin' always;
              add_header 'Access-Control-Allow-Origin' $origin always;
              add_header 'Access-Control-Allow-Methods' 'POST, OPTIONS' always;
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
