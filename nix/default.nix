{ sources ? import ./sources.nix, system ? __currentSystem }:
with {
  overlay = _: pkgs: {
    inherit (import sources.niv { }) niv;
    packages = pkgs.callPackages ./packages.nix { };
    inherit ((import sources.iohk-nix { }).rust-packages.pkgs)
      jormungandr jormungandr-cli;
  };
};
import sources.nixpkgs {
  overlays = [ overlay ];
  inherit system;
  config = { };
}
