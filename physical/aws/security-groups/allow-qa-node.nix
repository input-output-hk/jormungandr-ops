{ region, accessKeyId, ... }: {
  "allow-qa-node-${region}" = { nodes, resources, lib, ... }:
    let qaSourceIp = resources.elasticIPs.qa-1-ip;
    in {
      inherit region accessKeyId;
      _file = ./allow-allow-qa-node.nix;
      description = "QA node collection";
      rules = lib.optionals (nodes ? "qa-1") [
        {
          protocol = "tcp";
          fromPort = 3001;
          toPort = 3001; # jormungandr prometheus exporter
          sourceIp = qaSourceIp;
        }
      ];
    };
}
