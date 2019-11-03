{ region, accessKeyId, ... }:
let
  inherit (import ../../../globals.nix) deployerIp;
in {
  "allow-deployer-ssh-${region}" = {
    inherit region accessKeyId;
    _file = ./allow-deployer-ssh.nix;
    description = "SSH";
    rules = [{
      protocol = "tcp"; # TCP
      fromPort = 22;
      toPort = 22;
      sourceIp = "${deployerIp}/32";
    }];
  };
}
