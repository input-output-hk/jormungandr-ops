with { pkgs = import ./nix { }; };
pkgs.mkShell {
  buildInputs = with pkgs; [
    sqliteInteractive
    cacert
    crystal
    expect
    jormungandrEnv.packages.jcli
    niv
    nixops
    openssl
    zip
    delegateStake
    createStakePool
    cardano-wallet-jormungandr
  ];
}
