{ region, accessKeyId, ... }: {
  "allow-graylog-${region}" = {
    inherit region accessKeyId;
    _file = ./allow-graylog.nix;
    description = "Allow Graylog ${region}";
    rules = [{
      protocol = "tcp"; # all
      fromPort = 5044;
      toPort = 5044;
      sourceIp = "0.0.0.0/0";
    }];
  };
}
