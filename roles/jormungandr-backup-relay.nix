{ lib, name, ... }:
let
  pkgs = import ../nix { };
  inherit (pkgs.lib) mkForce;
in {
  imports = [ ../modules/jormungandr.nix ];

  services.jormungandr = {
    topicsOfInterest = {
      messages = "normal";
      blocks = "normal";
    };

    maxConnections = 4 * 1024;
    maxUnreachableNodes = 256;
    publicAddress = mkForce null;

    # policyQuarantineDuration = "10m";
    # topologyForceResetInterval = "30s";
  } // (if name == "relay-a-backup-1" then {
    package = mkForce pkgs.jormungandrLib.packages.v0_8_9.jormungandr-debug;
    jcliPackage = mkForce pkgs.jormungandrLib.packages.v0_8_9.jcli-debug;
  } else {
    package = mkForce pkgs.jormungandrLib.packages.v0_8_10.jormungandr-debug;
    jcliPackage = mkForce pkgs.jormungandrLib.packages.v0_8_10.jcli-debug;
  });
}
