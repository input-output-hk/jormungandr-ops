# example usage: nix-build generate-incentivized.nix -A tester
let
  ada = n: n * 1000000; # lovelace
  stakePoolCount = 11;
  stakePoolBalances = [ (ada 1) ];
  extraBlockchainConfig = {
    linear_fees = {
      constant = 2;
      coefficient = 1;
      certificate = 4;
    };

    treasury = 0;

    treasury_parameters = {
      fixed = 1000;
      ratio = "1/10";
    };

    total_reward_supply = ada 10000000;

    reward_parameters = {
      halving = {
        constant = 100;
        ratio = "13/19";
        epoch_start = 1;
        epoch_rate = 3;
      };
    };
  };
  inputParams =
    let
      readFile = file: (__replaceStrings ["\n"] [""] (__readFile file));
      #legacyAddrsToRemove = __attrNames mappedFunds;
      extraLegacyFunds = (__fromJSON (__readFile ~/utxo-accept-3441286.json)).fund;
      #extraDelegationCerts = map readFile [
      #  ../secrets/iohk/iohk.signcert
      #  ../secrets/cf/cf.signcert
      #  ../secrets/emurgo/emurgo.signcert
      #];
      #extraStakePools = map readFile [
      #  ../secrets/iohk/stake_delegation.signcert
      #  ../secrets/cf/stake_delegation.signcert
      #  ../secrets/emurgo/stake_delegation.signcert
      #];
    in {
      inherit extraLegacyFunds;
    };
  in import ./. { inherit inputParams stakePoolCount stakePoolBalances extraBlockchainConfig; }
