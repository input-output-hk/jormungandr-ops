self: super: {

    inherit ((import self.sources.iohk-nix {}).rust-packages.pkgs)
      jormungandr jormungandr-cli;

    inherit ((import self.sources.jormungandr-nix {}).scripts) janalyze;

}
