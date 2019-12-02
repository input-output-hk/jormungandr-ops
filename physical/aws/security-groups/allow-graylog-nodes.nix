{ lib, region, accessKeyId, nodes, ... }:
let
  inherit (lib) nameValuePair mapAttrsToList;
in {
  "allow-graylog-nodes-${region}" = ({resources, ...}: {
    inherit region accessKeyId;
    _file = ./allow-graylog-nodes.nix;
    description = "Allow Graylog nodes ${region}";
    rules = mapAttrsToList (subname: _:
      {
        protocol = "tcp"; # all
        fromPort = 5044;
        toPort = 5044;
        sourceIp = resources.elasticIPs."${subname}-ip";
      }
    ) nodes;
  });
}
