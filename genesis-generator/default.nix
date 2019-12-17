let
  ada = n: n * 1000000; # lovelace
  blockchainConfigDefaults = {
    block0_consensus = "genesis_praos";
    fees_go_to = "treasury";
    discrimination = "test";
    block_content_max_size = 1024000;
    block0_date = __currentTime;
    consensus_genesis_praos_active_slot_coeff = 0.1;
    consensus_leader_ids = [];
    epoch_stability_depth = 10;
    kes_update_speed = 86400;
    linear_fees = {
      constant = 200000;
      coefficient = 100000;
      certificate = 10000;
      per_certificate_fees = {
        certificate_pool_registration = ada 500;
        certificate_stake_delegation = 400000;
      };
    };
    slot_duration = 2;
    slots_per_epoch = 7200;

    treasury = 0;
    treasury_parameters = {
      fixed = 0;
      ratio = "1/10";
    };

    total_reward_supply = 701917808520000;

    reward_parameters = {
      linear = {
        constant = 3835616440000;
        ratio = "0/1";
        epoch_start = 1;
        epoch_rate = 1;
      };
    };

    reward_constraints = {
      reward_drawing_limit_max = "4109589/10000000000";
      pool_participation_capping = {
        min = 100;
        max = 100;
      };
    };
  };
in {
  stakePoolCount ? 7
, stakePoolBalances ? __genList (_: ada 10000000) stakePoolCount
, inputParams ? {}
, blockchainConfig ? blockchainConfigDefaults
, extraBlockchainConfig ? {}
}:

let
  pkgs = import ../nix { };
  inherit (pkgs) lib;

  inputConfig = __toFile "input.json" (__toJSON ({
    inherit stakePoolBalances stakePoolCount;
    inputBlockchainConfig = lib.recursiveUpdate blockchainConfig extraBlockchainConfig;
    extraLegacyFunds = [];
    extraFunds = [];
    extraDelegationCerts = [];
    extraStakePools = [];
  } // inputParams));

in lib.fix (self: {
  inherit (pkgs.jormungandrLib.environments.qa.packages) jcli jormungandr;
  inherit inputConfig;
  ghc = pkgs.haskellPackages.ghcWithPackages (ps: with ps; [ aeson turtle split ]);
  genesis-generator = pkgs.runCommand "genesis-generator" {
    buildInputs = [ self.ghc self.jcli pkgs.haskellPackages.ghcid ];
    preferLocalBuild = true;
  } ''
    cp ${./main.hs} main.hs
    mkdir -pv $out/bin/
    ghc ./main.hs -o $out/bin/genesis-generator
  '';

  helper = pkgs.writeShellScript "helper" ''
    set -e
    export PATH=${lib.makeBinPath [ self.jcli ]}:$PATH
    ${self.genesis-generator}/bin/genesis-generator ${inputConfig}
    jq . < genesis.yaml > genesis.yaml.tmp
    mv genesis.yaml.tmp genesis.yaml
    jcli --version
    jcli genesis encode < genesis.yaml > block-0.bin
  '';

  tester = pkgs.writeShellScript "tester" ''
    set -e
    export PATH=${lib.makeBinPath [ self.jcli self.jormungandr ]}:$PATH
    mkdir -p /tmp/testrun
    cd /tmp/testrun
    ${self.genesis-generator}/bin/genesis-generator ${inputConfig}
    jq . < genesis.yaml > genesis.yaml.tmp
    mv genesis.yaml.tmp genesis.yaml
    jcli --version
    jcli genesis encode < genesis.yaml > block-0.bin
    jormungandr --genesis-block block-0.bin
  '';
})
