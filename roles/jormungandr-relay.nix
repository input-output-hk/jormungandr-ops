{ lib, name, ... }: {
  imports = [ ../modules/jormungandr.nix ];

  services.jormungandr = {
    block0 = ../static/block-0.bin;
    topicsOfInterest = {
      messages = "normal";
      blocks = "normal";
    };
    policyQuarantineDuration = "10m";
    maxUnreachableNodes = 4096;
  };
}
