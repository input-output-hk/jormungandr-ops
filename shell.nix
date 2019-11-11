with { pkgs = import ./nix { }; };
pkgs.mkShell {
  buildInputs = with pkgs; [
    sqliteInteractive
    cacert
    crystal
    jormungandr-cli
    niv
    nixops
    openssl
    zip
  ];
}
