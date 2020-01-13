{ lib, name, ... }: {
  imports = [ ../modules/jormungandr.nix ];

  services.jormungandr = {
    topicsOfInterest = {
      messages = "normal";
      blocks = "normal";
    };
    maxConnections = 512;
    maxUnreachableNodes = 128;

    # For testing relay-a-backup-1 only
    #maxConnections = 512;
    #maxUnreachableNodes = 64;

    policyQuarantineDuration = "10m";
    # topologyForceResetInterval = "30s";
  };
}
