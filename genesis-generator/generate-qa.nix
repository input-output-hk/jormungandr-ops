# example usage: nix-build generate-qa.nix -A tester
let
  ada = n: n * 1000000; # lovelace
  stakePoolCount = 0;
  stakePoolBalances = [];
  readFile = file: (__replaceStrings ["\n"] [""] (__readFile file));
  extraBlockchainConfig = {
    slots_per_epoch = 750;
    fees_go_to = "rewards";
  };

  inputParams = {
    extraLegacyFunds = [
      { address = "DdzFFzCqrhtCWeg6PywoAR8wrza9DawkU2KgQddh7oi43LZy1kbZgZYK2hakgtXZu8Q7ptnhFjgV3ZgRgSypFhwtK9paG3ui17PiVUmB"; value = ada 1000000000; }
      { address = "DdzFFzCqrht1zDLWxw9hLEgzKogvkGH3KNNTCjADNreP8FTczsxMd7VG1k4qRHezZNQhgx6fHUa1NA54acajnENFymHxcEZrvgjG1p23"; value = ada 1000000000; }
      { address = readFile ../secrets/wallets/disasm_wallet.address; value = ada 500000000; }
      { address = readFile ../secrets/wallets/john_wallet.address; value = ada 500000000; }
    ];
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
  };
in import ./. { inherit inputParams stakePoolCount stakePoolBalances extraBlockchainConfig; }
