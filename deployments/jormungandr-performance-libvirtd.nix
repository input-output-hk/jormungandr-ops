import ../clusters/jormungandr-performance.nix {
  targetEnv = "libvirtd";
  tiny = ../physical/libvirtd/tiny.nix;
  large = ../physical/libvirtd/large.nix;
}
