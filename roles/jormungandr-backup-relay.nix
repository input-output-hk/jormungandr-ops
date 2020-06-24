{ lib, name, ... }:
let
  pkgs = import ../nix { };
  inherit (pkgs.lib) mkForce;
  #jormungandr = pkgs.jormungandrLib.packages.v0_9_0;
in {
  imports = [ ../modules/jormungandr.nix ];

  services.jormungandr = {
    topicsOfInterest = {
      messages = "normal";
      blocks = "normal";
    };

    maxConnections = 10000;
    maxUnreachableNodes = 1000;
    # publicAddress = mkForce null;

    policy.quarantineDuration = "10m";
    # topologyForceResetInterval = "30s";
    skipBootstrap = true;
  };
  # // (if name == "relay-a-backup-1" then {
  #   package = mkForce jormungandr.jormungandr-debug;
  #   jcliPackage = mkForce jormungandr.jcli-debug;
  # } else {
  #   package = mkForce jormungandr.jormungandr-debug;
  #   jcliPackage = mkForce jormungandr.jcli-debug;
  # });
}
