{ region, accessKeyId }: {
  "allow-jormungandr-${region}" = {
    inherit region accessKeyId;
    _file = ./allow-jormungandr.nix;
    description = "Allow jormungandr ${region}";
    rules = [{
      protocol = "tcp"; # all
      fromPort = 3000;
      toPort = 3000;
      sourceIp = "0.0.0.0/0";
    }];
  };
}
