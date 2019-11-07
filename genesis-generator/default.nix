let
  ada = n: n * 1000000; # lovelace
in {
  stakePoolCount ? 7
, stakePoolBalances ? __genList (_: ada 10000000) stakePoolCount
}:

let
  sources = import ../nix/sources.nix;
  commonLib = import sources.iohk-nix {};
  inherit (commonLib.pkgs) lib;
  pkgs = import sources.nixpkgs {};
  inputConfig = __toFile "input.json" (__toJSON {
    inherit stakePoolBalances stakePoolCount;
    inputBlockchainConfig = blockchainConfig;
    #utxoSnapshot = (builtins.fromJSON (builtins.readFile ~/utxo-accept-3191080.json)).fund;
    utxoSnapshot = [];
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
    slots_per_epoch = 7200;
  };
in lib.fix (self: {
  jcli = commonLib.rust-packages.pkgs.jormungandr-cli;
  jormungandr = commonLib.rust-packages.pkgs.jormungandr;
  ghc = pkgs.haskellPackages.ghcWithPackages (ps: with ps; [ aeson turtle split ]);
  genesis-generator = pkgs.runCommand "genesis-generator" { buildInputs = [ self.ghc self.jcli pkgs.haskellPackages.ghcid ]; inherit inputConfig; } ''
    cp ${./main.hs} main.hs
    mkdir -pv $out/bin/
    ghc ./main.hs -o $out/bin/genesis-generator
  '';
  helper = pkgs.writeShellScript "helper" ''
    set -e
    export PATH=${lib.makeBinPath [ self.jcli ]}:$PATH
    ${self.genesis-generator}/bin/genesis-generator ${inputConfig}
    jcli --version
    jcli genesis encode < genesis.yaml > block-0.bin
  '';
  tester = pkgs.writeShellScript "tester" ''
    set -e
    export PATH=${lib.makeBinPath [ self.jcli self.jormungandr ]}:$PATH
    mkdir -p /tmp/testrun
    cd /tmp/testrun
    ${self.genesis-generator}/bin/genesis-generator ${inputConfig}
    jcli --version
    jcli genesis encode < genesis.yaml > block-0.bin
    jormungandr --genesis-block block-0.bin
  '';
})
