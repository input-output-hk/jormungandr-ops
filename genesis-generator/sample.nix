# nix-build -A tester --arg inputParams 'import ./sample.nix'
let
  ada = n: n * 1000000; # lovelace
in {
  extraLegacyFunds = [
    { "address" = "DdzFFzCqrhtCWeg6PywoAR8wrza9DawkU2KgQddh7oi43LZy1kbZgZYK2hakgtXZu8Q7ptnhFjgV3ZgRgSypFhwtK9paG3ui17PiVUmB"; value = ada 100000; }
    { "address" = "DdzFFzCqrht1zDLWxw9hLEgzKogvkGH3KNNTCjADNreP8FTczsxMd7VG1k4qRHezZNQhgx6fHUa1NA54acajnENFymHxcEZrvgjG1p23"; value = ada 100000; }
  ];
  extraFunds = [
    #{ "address" = "addr1"; value = 1234; }
  ];
  extraDelegationCerts = [
    #"delegationcert"
  ];
  extraStakePools = [
    #"stakepoolcert"
  ];
}
