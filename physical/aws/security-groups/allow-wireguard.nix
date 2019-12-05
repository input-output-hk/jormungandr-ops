{ region, accessKeyId, ... }: {
  "allow-wireguard-${region}" = {
    inherit region accessKeyId;
    _file = ./allow-wireguard.nix;
    description = "Wireguard";
    rules = [{
      protocol = "udp";
      fromPort = 17777;
      toPort = 17777;
      sourceIp = "0.0.0.0/0";
    }];
  };
}
