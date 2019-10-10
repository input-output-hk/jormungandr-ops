{ pkgs, ... }: {
  deployment.targetEnv = "libvirtd";
  deployment.libvirtd.headless = true;
  nixpkgs.localSystem.system = "x86_64-linux";
}
