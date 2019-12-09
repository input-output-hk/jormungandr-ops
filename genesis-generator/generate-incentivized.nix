# example usage: nix-build generate-incentivized.nix -A tester
let
  ada = n: n * 1000000; # lovelace
  stakePoolCount = 0;
  stakePoolBalances = [ (ada 1) ];
  extraBlockchainConfig = {
    slots_per_epoch = 43200;
  };
  inputParams =
    let
      readFile = file: (__replaceStrings ["\n"] [""] (__readFile file));
      #legacyAddrsToRemove = __attrNames mappedFunds;
      extraLegacyFunds = (__fromJSON (__readFile ~/utxo-accept-3441286.json)).fund ++ [
        { address = readFile ../secrets/wallets/disasm_wallet.address; value = ada 1000000000; }
        { address = readFile ../secrets/wallets/clever_wallet.address; value = ada 1000000000; }
        { address = readFile ../secrets/wallets/john_wallet.address; value = ada 1000000000; }
        { address = readFile ../secrets/wallets/manveru_wallet.address; value = ada 1000000000; }
      ];
      # 1 lovelace for each initial stake pool so we can create blocks
      extraFunds = [
        { address = readFile ../secrets/pools/IOHK1_owner_wallet.address; value = 1; }
        { address = readFile ../secrets/pools/IOHK2_owner_wallet.address; value = 1; }
        { address = readFile ../secrets/pools/IOHK3_owner_wallet.address; value = 1; }
        { address = readFile ../secrets/pools/IOHK4_owner_wallet.address; value = 1; }
        { address = readFile ../secrets/pools/IOHK5_owner_wallet.address; value = 1; }
        { address = readFile ../secrets/pools/IOHK6_owner_wallet.address; value = 1; }
        { address = readFile ../secrets/pools/IOHK7_owner_wallet.address; value = 1; }
        { address = readFile ../secrets/pools/IOHK8_owner_wallet.address; value = 1; }

      ];
      extraDelegationCerts = map readFile [
        ../secrets/pools/IOHK1-delegation.signcert
        ../secrets/pools/IOHK2-delegation.signcert
        ../secrets/pools/IOHK3-delegation.signcert
        ../secrets/pools/IOHK4-delegation.signcert
        ../secrets/pools/IOHK5-delegation.signcert
        ../secrets/pools/IOHK6-delegation.signcert
        ../secrets/pools/IOHK7-delegation.signcert
        ../secrets/pools/IOHK8-delegation.signcert
      ];
      extraStakePools = map readFile [
        ../secrets/pools/IOHK1.signcert
        ../secrets/pools/IOHK2.signcert
        ../secrets/pools/IOHK3.signcert
        ../secrets/pools/IOHK4.signcert
        ../secrets/pools/IOHK5.signcert
        ../secrets/pools/IOHK6.signcert
        ../secrets/pools/IOHK7.signcert
        ../secrets/pools/IOHK8.signcert
      ];
    in {
      inherit extraLegacyFunds extraFunds extraStakePools extraDelegationCerts;
    };
  in import ./. { inherit inputParams stakePoolCount stakePoolBalances extraBlockchainConfig; }
