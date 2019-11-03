with { pkgs = import ./nix { }; };
pkgs.mkShell {
  buildInputs = with pkgs; [ niv nixops cacert sqliteInteractive zip jormungandr-cli openssl ];
}
