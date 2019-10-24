let
  sources = import ../nix/sources.nix;
  jlib = import "${sources.jormungandr-nix}/lib.nix";
  inherit (jlib) lib;
  pkgs = import sources.nixpkgs {};
  inputConfig = __toFile "input.json" (__toJSON {
    stakePoolBalances = [ 1 2 3 ];
    stakePoolCount = 4;
  });
in lib.fix (self: {
  jcli = jlib.pkgs.jormungandr-cli;
  ghc = pkgs.haskellPackages.ghcWithPackages (ps: with ps; [ aeson turtle ]);
  thing = pkgs.runCommand "thing" { buildInputs = [ self.ghc self.jcli ]; src = ./.; inherit inputConfig; } ''
    unpackPhase
    cd $sourceRoot
    mkdir -pv $out/bin/
    ghc ./main.hs -o $out/bin/thing
  '';
})
