# example usage: nix-build generate-incentivized.nix -A tester
let
  ada = n: n * 1000000; # lovelace
  blockchainConfig = {
    bft_slots_ratio = 0;
    block0_consensus = "genesis_praos";
    block0_date = 1573560000;
    consensus_genesis_praos_active_slot_coeff = 0.1;
    consensus_leader_ids = [];
    discrimination = "test";
    epoch_stability_depth = 10;
    kes_update_speed = 86400;
    linear_fees = {
      certificate = 10000000000;
      coefficient = 50;
      constant = 500000;
    };
    max_number_of_transactions_per_block = 255;
    slot_duration = 2;
    slots_per_epoch = 432000;
  };
  stakePoolCount = 0;
  inputParams =
    let
      readFile = file: (__replaceStrings ["\n"] [""] (__readFile file));
      mappedFunds = {
        "DdzFFzCqrht2WKNEFqHvMSumSQpcnMxcYLNNBXPYXyHpRk9M7PqVjZ5ysYzutnruNubzXak2NxT8UWTFQNzc77uzjQ1GtehBRBdAv7xb" = readFile ../secrets/iohk/iohk_owner_wallet.address;
        "Ae2tdPwUPEZ8zMjtfmWoC99npJxJx1trkaKghaZW3MeXoJmr46C3qkqg5gr" = readFile ../secrets/emurgo/emurgo_owner_wallet.address;
        "DdzFFzCqrhsgwQmeWNBTsG8VjYunBLK9GNR93GSLTGj1FeMm8kFoby2cTHxEHBEraHQXmgTtFGz7fThjDRNNvwzcaw6fQdkYySBneRas" = readFile ../secrets/cf/cf_owner_wallet.address;
      };
      legacyAddrsToRemove = __attrNames mappedFunds;
      initial = (__fromJSON (__readFile ~/utxo-accept-3367845.json)).fund;
      # right is legacy addrs to be upgraded
      # wrong is the legacy funds being left as-is
      split = __partition (fund: __elem fund.address legacyAddrsToRemove) initial;
      migratedFunds = split.wrong;
      replacedFunds = map (fund: { address = mappedFunds.${fund.address}; value = fund.value; }) split.right;
      extraDelegationCerts = map readFile [
        ../secrets/iohk/iohk.signcert
        ../secrets/cf/cf.signcert
        ../secrets/emurgo/emurgo.signcert
      ];
      extraStakePools = map readFile [
        ../secrets/iohk/stake_delegation.signcert
        ../secrets/cf/stake_delegation.signcert
        ../secrets/emurgo/stake_delegation.signcert
      ];
    in {
      inherit extraStakePools extraDelegationCerts;
      extraLegacyFunds = migratedFunds;
      extraFunds = replacedFunds;
    };
  in import ./. { inherit inputParams stakePoolCount blockchainConfig; }
