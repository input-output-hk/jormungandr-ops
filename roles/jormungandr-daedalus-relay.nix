{ lib, name, ... }:
let
  pkgs = import ../nix { };
  inherit (lib) mkForce;
in {
  imports = [ ../modules/jormungandr.nix ];

  services.jormungandr = {
    topicsOfInterest = {
      messages = "normal";
      blocks = "normal";
    };

    maxConnections = 2 * 1024;
    maxUnreachableNodes = 1024;
    maxBootstrapAttempts = 0;

    policy.quarantineDuration = "10m";
    # topologyForceResetInterval = "30s";

    #package = mkForce pkgs.jormungandrLib.packages.master.jormungandr-debug;
    #jcliPackage = mkForce pkgs.jormungandrLib.packages.master.jcli-debug;
  };
}
