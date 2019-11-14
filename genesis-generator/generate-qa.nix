# example usage: nix-build generate-qa.nix -A tester
let
  ada = n: n * 1000000; # lovelace
  stakePoolCount = 7;
  stakePoolBalances = __genList (_: ada 10000000) stakePoolCount;
  inputParams = {
    extraLegacyFunds = [
      { "address" = "DdzFFzCqrhtCWeg6PywoAR8wrza9DawkU2KgQddh7oi43LZy1kbZgZYK2hakgtXZu8Q7ptnhFjgV3ZgRgSypFhwtK9paG3ui17PiVUmB"; value = ada 100000; }
      { "address" = "DdzFFzCqrht1zDLWxw9hLEgzKogvkGH3KNNTCjADNreP8FTczsxMd7VG1k4qRHezZNQhgx6fHUa1NA54acajnENFymHxcEZrvgjG1p23"; value = ada 100000; }
    ];
    extraFunds = [
    ];
    extraDelegationCerts = [
    ];
    extraStakePools = [
    ];
  };
in import ./. { inherit inputParams stakePoolCount stakePoolBalances; }
