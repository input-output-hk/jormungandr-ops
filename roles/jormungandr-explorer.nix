{ lib, ... }: {
  imports = [ ./jormungandr-relay.nix ];

  services.jormungandr-explorer = {
    enable = true;
    virtualHost = "explorer";
    enableSSL = false;
    jormungandrApi = "http://explorer/explorer/graphql";
  };

  services.jormungandr.rest.cors.allowedOrigins = [ "http://explorer" ];
  services.nginx.mapHashBucketSize = 64;
}
