# example usage: nix-build generate-legacy.nix -A tester
let
  ada = n: n * 1000000; # lovelace
  mada = n: n * 1000000 * 1000000; # million ada in lovelace
  stakePoolCount = 0;
  stakePoolBalances = [];
  readFile = file: (__replaceStrings ["\n"] [""] (__readFile file));
  extraBlockchainConfig = {
    slots_per_epoch = 900;
  };

  inputParams = {
    extraLegacyFunds = [
      # Stake delegated by IOHK to IOHK stake pools
      { address = readFile ../secrets/wallets/iohk_a.address; value = mada 500; }
      # Stake delegated by IOHK to community stake pools
      { address = readFile ../secrets/wallets/iohk_b.address; value = mada 500; }
      # Community Stake Pools
      { address = readFile ../secrets/wallets/disasm_wallet.address; value = mada 25; }
      { address = readFile ../secrets/wallets/john_wallet.address; value = mada 25; }
      { address = readFile ../secrets/wallets/manveru_wallet.address; value = mada 25; }
      { address = readFile ../secrets/wallets/charles_wallet.address; value = mada 25; }
      { address = "2w1sdSJu3GVeuuY9W1Mf6D1xUUfMrMe1nwKxWt8AFKUGGHV349QRLvQNZFwdRyiWmRrPcVqYGubRkZVQwyD1SR1npgNvTa9tyYx"; value = mada 25; }
      { address = "DdzFFzCqrhtCWeg6PywoAR8wrza9DawkU2KgQddh7oi43LZy1kbZgZYK2hakgtXZu8Q7ptnhFjgV3ZgRgSypFhwtK9paG3ui17PiVUmB"; value = mada 25; }
      { address = "DdzFFzCqrhsoip4B4BZzRT4rVab9u8x7jyUWmNF63UAVUS671RQaKB2zquDK2FwfCKrrTQ2ZDX2gMTQxoSz6xAWYGxySMCAL7CyEXEWC"; value = mada 25; }
      { address = "DdzFFzCqrhsq8uMsszGRuzho2kQUMBdPCF5ZGBYqcH6MK34WgkYPhF4feMjFWCofcjhoW4ccNFJFQ1sPaQChma6NJD1uiVQR6wY2PFUy"; value = mada 25; }
      { address = "DdzFFzCqrhsj7AEaDTt9KTKFSzP3DvMNmYb29CVHukYCgXeCuysPKaMp9wPE21bsZLp4tQajgo86V8WLGHzESAMTxkzmuLRoaP3YDoMa"; value = mada 25; }
      { address = "Ae2tdPwUPEZGiUExztwe7em8yKbasWR7fb46fm8yPxZctyYAPV5Fc6wpGwY"; value = mada 25; }
      { address = "DdzFFzCqrhskfzbJsyYZzkJjjWMYJUKeE3q9B3sfboL2RHkx4KjPawBoWauevBQnUzyvgEZfSir4z8Nxf8HmGdPHhmeBSJ34dttxGyCS"; value = mada 25; }
      { address = "DdzFFzCqrhssutyA2q4DdBxNyx5kWzeJ6TKX3UF1MPWXvRFGrr6nZ3gu8tHdfUftt5rq7cPZXZ8TH7dvxwY9ZFZQYdkLtKNnf5SXbH5u"; value = mada 25; }
      { address = "DdzFFzCqrhshvg2Q3TnXv4rRMkrYQxeCp9wVCvRw46NvC7v5iH7vRfXvGFn2AS6mfh3w1cuT9jmpdXp5LTpxroeWtLYrWbiG2gARJQSR"; value = mada 25; }
      { address = "DdzFFzCqrhsqsfGv1wTU1iycdpEfsFPLs8dvE3TBbSrXQ38Pop2A6BALYVqxu6Gb66ZCf8kAR4Nm2mvHTDLgsQXhh8sEjh4b9XwuxMeC"; value = mada 25; }
      { address = "DdzFFzCqrhtC5HBksij49oAbcndoT1MKkLT3cWnGf7uUtNm1hPbsYS2H4HuHVDp8FnAFSBHo6eSE2kQTF74ew2VhrwVNZ441bE7cJqNY"; value = mada 25; }
      { address = "DdzFFzCqrhsgvB9VpBmQQgwZMtxfXpTbnvi6wj3w6LVnsUi7ETtFbn2Yr18EKRNguP7S8YHKwDPMHHdNCJf6vxSd474Awq6FZb5xaTKA"; value = mada 25; }
      { address = "DdzFFzCqrhsu4uSoqCP5L8xTNKV2Tw5sNUZm4PKwGv5Qk5txYbXXJCKKW1RSdriBy4QwgXaWeq5sY9QjktT6BjtgPp3tEQsTf8PKETTC"; value = mada 25; }
      { address = "Ae2tdPwUPEYw3rz8KGHbnTusd9QWQ8ePhogEWkm1agugTtW51skA59DrKe8"; value = mada 25; }
      { address = "DdzFFzCqrht6KNtLvVdU3Q4Wkznj7htnYBEkkVx1QibX6LUYBVyaJgXxGENPE7mdom5EGMp3m453jAigYGWSUuZNhq5ef4Tx881DPV4S"; value = mada 25; }
      { address = "Ae2tdPwUPEZ1uPQNb4dNrXQdxxjVjwNPceyFvmBuhmbx52vmnR2otHhKNGn"; value = mada 25; }
      { address = "DdzFFzCqrhsu4uSoqCP5L8xTNKV2Tw5sNUZm4PKwGv5Qk5txYbXXJCKKW1RSdriBy4QwgXaWeq5sY9QjktT6BjtgPp3tEQsTf8PKETTC"; value = mada 25; }
      { address = "DdzFFzCqrhsdzdJZjw5LiScJtWhPYjeLFSeBPCj6iKNYgJwDppsQZGMPixc26yWwhnAf5CgwiLNfHsjccUTAHhjwtLXBVtSUAnAgKUHT"; value = mada 25; }
      { address = "DdzFFzCqrht9Qj3FefrpkeP2y84NMNJTx6x4h7sZ1NBTJjjzCUEo8iwM9LtrvgGMVsJ83bn12huopCveUD72Lj3biQC5Ni73xrTQ9moX"; value = mada 25; }
      { address = "DdzFFzCqrht9uW98NkitQYsAatp6xgzBp5hgVR5wvUHRRJpaR5Nmq77a6qHVyHozUJXaa8yf9tJR5vCaadXKwpg4R5F7GUou3gU6bSAu"; value = mada 25; }
      { address = "DdzFFzCqrhsxhkudZezWjTDFpasvhASnVakDXnVy7yiieNT97akyjEtAyoBEdsej2svfhGHuqXvM9LLEHx9GuLBWuoNF2P8E71s6LSQa"; value = mada 25; }
      { address = "DdzFFzCqrhsgN148z1GUHDGTWBor65kkdLzLBn9eUfkRBBY2Kg5qcPYVYUeWU1RB4mKk4F2ShT8Gc7pPM46NjrwRMD5jXEVfFSyNxpbL"; value = mada 25; }
      { address = "DdzFFzCqrhsySXcvRpVATZco2yyaQBoDckbf9VMwE1Uftc1csGModayMgRsmtJeV37zLGMsbvAme24pv56nuqPo2xyNYZd1ukDRpRx2m"; value = mada 25; }
      { address = "DdzFFzCqrht9pcAmGr8E4Lk9QA1UsoPS4WnYneW5V6tcVFxvFXadJac53G4A8J8VqqF8RCUbFtjfyuSB47hpikGM41qvGHH6xoR7tdus"; value = mada 25; }
      { address = "DdzFFzCqrhshKFUZs2ndoHsmdfiTmzgaRVtwHfx1GeHAXbjCGzrx5TJSvgk7pXu7cvNXAp8DCWNvst45No4UGbsJEFnZixhJSdosk3bd"; value = mada 25; }
      { address = "DdzFFzCqrhsgaYBNK2XccfqnZeVNGnuwFmDnnjQoKnHPgBBRMKnMMQagHDcPg4XhAu8Wea9JNPeeFBpR1wBmYBEWoUQgx1qH3HWMKa55"; value = mada 25; }
      { address = "DdzFFzCqrhsgLw2Po6vDQSx3tcXUjhBLqW4He18nf4xtyJKXFHa4v9WYkA1TkCmHpnmWyoFpQHmTHLc33TaogqHfc52Kx7cG1UyUdMLC"; value = mada 25; }
      { address = "DdzFFzCqrhsuMmzgHfCLFjPa2Dkowx8xGKHqjZv79JKsB8TZpq5y5SnWZro1SMCrcd8pVhHQ1q4ev6SA9bhamyrh6GqcDcKa5iKsob4H"; value = mada 25; }
      { address = "DdzFFzCqrhtAjtxH7CtTV8SAU4EGYdt8cPnDt582QeWLJU8GwtJHNzk9ksDhz66LcZLrsA8zoKk5d77CLY7rWZ9WZFyQzGYw7nYFnUPi"; value = mada 25; }
      { address = "DdzFFzCqrhsidXcWsndrtJc3zL6yHtZQ21ibU8iFRYaacEnn8DT9AJ6NExmcpv8rQGEj97GpXpVYikZs3gcpsp4KTKKGzF8rzuHx6K84"; value = mada 25; }
      { address = "DdzFFzCqrhsz4WA6TDzRHjwp1EKNbEYH3XTVtzRMmma8rjFvq2Uieij2j2YVKmEvXuxP2hZfGNvnV8gyRjtvjtL5sQRMjwoELVi576z8"; value = mada 25; }
      { address = "Ae2tdPwUPEZ13TbCDMQsfyAHPbbxCaB1V3qgAAVZRU8EC4zeqe3MvuhnWQT"; value = mada 25; }
      { address = "DdzFFzCqrhsg72hf4sARqduZmqz1F23iqu73xxCawhCaLCtGZXg9EGpLjk3UdoeGXoPHCCw4WfEKux93u6SL9SdPaXNTPrUnYgt6jTNW"; value = mada 25; }
      { address = "DdzFFzCqrhsytzLXcKmi1ckPJjKyiwQUc2vB17y4jDRNoAcxU13ZpLo1zWJ4BrXpeTSu9z3pX8k4dmt5FGfVd7WNGz2MveaCAM7JRTJy"; value = mada 25; }
      { address = "DdzFFzCqrht4UcZbuLrmFymJwqEYyUUoi7NBrPpCs2CaLBYYtEZ5xbEa84fnzhKu8Ba7hnMexffV7iYz5aaE1Bhfg6HNrDPjqe3WaHp2"; value = mada 25; }
      { address = "DdzFFzCqrhspzgcyDa9DfHaLnZbtjoNfhoLeKT7GTC5bDNHL7yfo5HksaCgzMX8tXvKWM8EW6y9pMYjXHwDbUWSmLP81fNSTdCaMkPtw"; value = mada 25; }
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
