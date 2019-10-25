let
  sources = import ../nix/sources.nix;
  jlib = import "${sources.jormungandr-nix}/lib.nix";
  inherit (jlib) lib;
  pkgs = import sources.nixpkgs {};
  ada = n: n * 1000000; # lovelace
  inputConfig = __toFile "input.json" (__toJSON {
    stakePoolBalances =
      (__genList (_: ada 1000000) 50) ++
      (__genList (_: ada 35000) 1450);
    stakePoolCount = 1500;
    #stakePoolCount = 10;
    inputBlockchainConfig = blockchainConfig;
  });

  blockchainConfig = {
    bft_slots_ratio = 0;
    block0_consensus = "genesis_praos";
    block0_date = __currentTime;
    consensus_genesis_praos_active_slot_coeff = 0.1;
    consensus_leader_ids = [];
    discrimination = "test";
    epoch_stability_depth = 10;
    kes_update_speed = 86400;
    linear_fees = {
      certificate = 10000;
      coefficient = 50;
      constant = 1000;
    };
    max_number_of_transactions_per_block = 255;
    slot_duration = 2;
    slots_per_epoch = 900;
  };
in lib.fix (self: {
  jcli = jlib.pkgs.jormungandr-cli;
  jormungandr = jlib.pkgs.jormungandr;
  ghc = pkgs.haskellPackages.ghcWithPackages (ps: with ps; [ aeson turtle split ]);
  thing = pkgs.runCommand "thing" { buildInputs = [ self.ghc self.jcli pkgs.haskellPackages.ghcid ]; src = ./.; inherit inputConfig; } ''
    unpackPhase
    cd $sourceRoot
    mkdir -pv $out/bin/
    ghc ./main.hs -o $out/bin/thing
  '';
  helper = pkgs.writeShellScript "helper" ''
    set -e
    export PATH=${lib.makeBinPath [ self.jcli ]}:$PATH
    ${self.thing}/bin/thing ${inputConfig}
    jcli --version
    jcli genesis encode < genesis.yaml > block-0.bin
  '';
  tester = pkgs.writeShellScript "helper" ''
    set -e
    export PATH=${lib.makeBinPath [ self.jcli self.jormungandr]}:$PATH
    mkdir -p /tmp/testrun
    cd /tmp/testrun
    ${self.thing}/bin/thing ${inputConfig}
    jcli --version
    jcli genesis encode < genesis.yaml > block-0.bin
    jormungandr --genesis-block block-0.bin
  '';
})
