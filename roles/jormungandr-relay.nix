{ lib, name, ... }: {
  imports = [ ../modules/jormungandr.nix ];

  services.jormungandr = {
    block0 = ../static/block-0.bin;
  };
}
