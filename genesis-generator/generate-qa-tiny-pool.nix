# example usage: nix-build generate-qa-tiny-pool.nix -A tester
let
  ada = n: n * 1000000; # lovelace
  stakePoolCount = 1;
  stakePoolBalances = [ (ada 1) ];
  inputParams = {
    extraLegacyFunds = [
      { "address" = "DdzFFzCqrhtCWeg6PywoAR8wrza9DawkU2KgQddh7oi43LZy1kbZgZYK2hakgtXZu8Q7ptnhFjgV3ZgRgSypFhwtK9paG3ui17PiVUmB"; value = ada 100000000; }
    ];
    extraFunds = [
    ];
    extraDelegationCerts = [
    ];
    extraStakePools = [
    ];
  };
in import ./. { inherit inputParams stakePoolCount stakePoolBalances; }
