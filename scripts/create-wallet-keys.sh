#! /usr/bin/env bash
set -euo pipefail

[ $# -eq 0 ] && { echo "No arguments provided.  Use -h for help."; exit 1; }

WALLET_PREFIX="${WALLET_PREFIX:-"wallet"}"
SECOND_FACTOR="${SECOND_FACTOR:-""}"
while getopts 'n:p:s:h' c
do
  case "$c" in
    n) NUM_WALLETS="$OPTARG" ;;
    p) WALLET_PREFIX="$OPTARG" ;;
    s) SECOND_FACTOR="$OPTARG" ;;
    *)
       echo "This command creates n sets of wallet mnemonic and corresponding secret key files in the cwd."
       echo "usage: $0 -n [-h]"
       echo ""
       echo "  -n number of sets of wallet mnemonic and key files to create"
       echo "  -p filename prefix (defaults to \"wallet\")"
       echo "  -s second factor keywords (defaults to \"\")"
       exit 0
       ;;
  esac
done

if [ -z "${NUM_WALLETS:-}" ]; then
  echo "-n is a required parameter"
  exit 1
fi

if ! [[ $NUM_WALLETS =~ ^[0-9]+$ ]]; then
  echo "-n is not a positive integer"
  exit 1
fi

for i in $(seq 1 "$NUM_WALLETS"); do
  MNEMONIC="$(cardano-wallet-jormungandr mnemonic generate)"
  echo "$MNEMONIC" > "${WALLET_PREFIX}${i}.mnemonic"
  SK_OUT="${WALLET_PREFIX}${i}.sk"
  MNEMONIC=$MNEMONIC SECOND_FACTOR=$SECOND_FACTOR SK_OUT=$SK_OUT expect << 'END' > /dev/null
    set chan [open $::env(SK_OUT) w]
    set timeout 10
    spawn cardano-wallet-jormungandr mnemonic reward-credentials
    sleep 0.05
    expect "Please enter your 15–24 word mnemonic sentence: "
    send -- "$::env(MNEMONIC)\r"
    sleep 0.05
    expect "(Enter a blank line if you didn't use a second factor.)"
    expect "Please enter your 9–12 word mnemonic second factor: "
    send -- "$::env(SECOND_FACTOR)\r"
    expect "\r"
    expect "Here's your reward account private key:"
    expect "\r"
    expect -re "(\[a-zA-Z_0-9]+)"
    set KEY $expect_out(1,string)
    expect "\r"
    expect "Keep it safe!"
    puts $chan $KEY
    close $chan
    exit 0
END
  done
