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

    maxConnections = 2 * 1024;
    maxUnreachableNodes = 1024;

    # policyQuarantineDuration = "10m";
    # topologyForceResetInterval = "30s";
  };
}
