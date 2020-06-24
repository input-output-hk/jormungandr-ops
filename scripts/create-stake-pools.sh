#!/usr/bin/env bash

set -ex

rm -rf secrets/pools
mkdir -p secrets/pools
cd secrets/pools

create-stake-pool -t IOHK1 -f 258251123 -r 2/25 -u https://staking.cardano.org/ -n "IOHK Stakepool" 
create-stake-pool -t IOHK2 -f 258251123 -r 1/10 -u https://staking.cardano.org/ -n "IOHK Stakepool" 
create-stake-pool -t IOHK3 -f 258251123 -r 3/25 -u https://staking.cardano.org/ -n "IOHK Stakepool" 
create-stake-pool -t IOHK4 -f 258251123 -r 7/50 -u https://staking.cardano.org/ -n "IOHK Stakepool" 
create-stake-pool -t IOHK5 -f 258251123 -r 1/1  -u https://staking.cardano.org/ -n "IOHK Private Stakepool"
create-stake-pool -t IOHK6 -f 258251123 -r 1/1  -u https://staking.cardano.org/ -n "IOHK Private Stakepool"

mv state-jormungandr-*/* ./
rmdir state-jormungandr-*

for i in $(seq 1 6); do
  delegate-stake -s "IOHK${i}_owner_wallet.prv" -p "$(< IOHK${i}.id)"
  mv state-jormungandr-*/stake_delegation.signcert "IOHK${i}-delegation.signcert"
  mv state-jormungandr-*/stake_delegation.cert "IOHK${i}-delegation.cert"
done

rm secret.yaml
