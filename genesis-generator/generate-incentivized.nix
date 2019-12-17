# example usage: nix-build generate-incentivized.nix -A tester
let
  ada = n: n * 1000000; # lovelace
  mada = n: n * 1000000 * 1000000; # million ada in lovelace
  stakePoolCount = 0;
  stakePoolBalances = [];
  readFile = file: (__replaceStrings ["\n"] [""] (__readFile file));
  extraBlockchainConfig = {
    slots_per_epoch = 43200;
  };

  inputParams =
    let
      #legacyAddrsToRemove = __attrNames mappedFunds;
      extraLegacyFunds = (__fromJSON (__readFile ~/utxo-accept-3441286.json)).fund;
      # 1 lovelace for each initial stake pool so we can create blocks
      extraFunds = [
        { address = readFile ../secrets/pools/iohk_owner_wallet_1.address; value = 1; }
        { address = readFile ../secrets/pools/iohk_owner_wallet_2.address; value = 1; }
        { address = readFile ../secrets/pools/iohk_owner_wallet_3.address; value = 1; }
        { address = readFile ../secrets/pools/iohk_owner_wallet_4.address; value = 1; }
        { address = readFile ../secrets/pools/iohk_owner_wallet_5.address; value = 1; }
        { address = readFile ../secrets/pools/iohk_owner_wallet_6.address; value = 1; }
      ];
      extraDelegationCerts = map readFile [
        ../secrets/pools/iohk_1_stake_delegation.signcert
        ../secrets/pools/iohk_2_stake_delegation.signcert
        ../secrets/pools/iohk_3_stake_delegation.signcert
        ../secrets/pools/iohk_4_stake_delegation.signcert
        ../secrets/pools/iohk_5_stake_delegation.signcert
        ../secrets/pools/iohk_6_stake_delegation.signcert
      ];
      extraStakePools = map readFile [
        ../secrets/pools/iohk_1.signcert
        ../secrets/pools/iohk_2.signcert
        ../secrets/pools/iohk_3.signcert
        ../secrets/pools/iohk_4.signcert
        ../secrets/pools/iohk_5.signcert
        ../secrets/pools/iohk_6.signcert
      ];
    in {
      inherit extraLegacyFunds extraFunds extraStakePools extraDelegationCerts;
    };
  in import ./. { inherit inputParams stakePoolCount stakePoolBalances extraBlockchainConfig; }
