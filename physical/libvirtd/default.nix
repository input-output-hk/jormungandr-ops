{ pkgs, name, ... }:
let inherit (import ../../globals.nix) domain;
in {
  deployment.libvirtd.headless = true;
  nixpkgs.localSystem.system = "x86_64-linux";

  node = { fqdn = "${name}.${domain}"; };
}
