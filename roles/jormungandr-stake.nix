{ lib, name, ... }:
let
  pkgs = import ../nix { };
  poolNumber = __elemAt (lib.splitString "-" name) 1;
in {
  imports = [ ../modules/jormungandr.nix ];

  services.jormungandr = {
    secrets-paths = [ "/run/keys/secret_pool.yaml" ];
    topicsOfInterest = {
      messages = "high";
      blocks = "high";
    };
    maxConnections = 256;
    maxUnreachableNodes = 5;
    # gossipInterval = "3s";
  };

  users.users.jormungandr.extraGroups = [ "keys" ];

  systemd.services."jormungandr" = {
    after = [ "secret_pool.yaml-key.service" ];
    wants = [ "secret_pool.yaml-key.service" ];
  };
}
