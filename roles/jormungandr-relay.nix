{ lib, name, ... }:
let
  pkgs = import ../nix { };
  inherit (pkgs) jormungandr-cli runCommandNoCC;
in {
  imports = [ ../modules/jormungandr.nix ];

  services.jormungandr = {
    block0 = ../static/block-0.bin;
  };
}
