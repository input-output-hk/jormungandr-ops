# example usage: nix-build generate-nightly.nix -A tester
let
  ada = n: n * 1000000; # lovelace
  stakePoolCount = 7;
  stakePoolBalances = __genList (_: ada 100000000) stakePoolCount;
  readFile = file: (__replaceStrings ["\n"] [""] (__readFile file));

  inputParams = {
    extraLegacyFunds = [
      { "address" = "DdzFFzCqrhtCWeg6PywoAR8wrza9DawkU2KgQddh7oi43LZy1kbZgZYK2hakgtXZu8Q7ptnhFjgV3ZgRgSypFhwtK9paG3ui17PiVUmB"; value = ada 1000000000; }
      { "address" = "DdzFFzCqrht1zDLWxw9hLEgzKogvkGH3KNNTCjADNreP8FTczsxMd7VG1k4qRHezZNQhgx6fHUa1NA54acajnENFymHxcEZrvgjG1p23"; value = ada 1000000000; }
      { address = readFile ../secrets/wallets/disasm_wallet.address; value = ada 1000000000; }
      { address = readFile ../secrets/wallets/clever_wallet.address; value = ada 1000000000; }
      { address = readFile ../secrets/wallets/john_wallet.address; value = ada 1000000000; }
      { address = readFile ../secrets/wallets/manveru_wallet.address; value = ada 1000000000; }
    ];
    extraFunds = [
      { address = "ca1s5j5kpfd6kwehx6r4ttq3mgdddd9ald97e3pcg0zn9m9493hq9axctwxjl4"; value = ada 10000000; }
      { address = "ca1shmg2lghpxvsmgjz4duewzka5xn7z5rsk6aljtdsjzfpx8hcgjlyq2ks36q"; value = ada 10000000; }
      { address = "ca1s5an22g0k9xq4jww0n0yqgzfymsnk8p8587nw4kxnqgcxf9lq52dwqgusv0"; value = ada 10000000; }
      { address = "ca1sk5nh8kkcsw4gcda7fyszfaxwrmyndh9r447yrjx4kzwpgnmlpmdqkr5lm4"; value = ada 10000000; }
    ];
  };
in import ./. { inherit inputParams stakePoolCount stakePoolBalances; }
