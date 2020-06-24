{ lib, name, ... }:
let
  pkgs = import ../nix { };
in {
  imports = [ ../modules/jormungandr.nix ];

  services.jormungandr = {
    topicsOfInterest = {
      messages = "normal";
      blocks = "normal";
    };
    maxConnections = 4 * 1024;
    # package = lib.mkForce pkgs.jormungandrLib.packages.v0_8_9.jormungandr-debug;
    # jcliPackage = lib.mkForce pkgs.jormungandrLib.packages.v0_8_9.jcli-debug;
    # maxUnreachableNodes = 256;
    # policy.quarantineDuration = "10m";
    # topologyForceResetInterval = "30s";
  };
}
