{ lib, name, ... }:
let
  pkgs = import ../nix { };
  inherit (pkgs) jormungandr-cli runCommandNoCC;
in {
  imports = [ ../modules/jormungandr.nix ];

  services.jormungandr = {
    genesisBlockHash = lib.fileContents (runCommandNoCC "genesisHash" { } ''
      ${jormungandr-cli}/bin/jcli genesis hash < ${../static/block-0.bin} > $out
    '');
  };
}
