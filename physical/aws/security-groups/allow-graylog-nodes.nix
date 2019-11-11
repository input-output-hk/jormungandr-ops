{ lib, region, accessKeyId, nodes, ... }:
let
  inherit (lib) foldl' recursiveUpdate mapAttrs' nameValuePair flip;
in flip mapAttrs' nodes (name: node:
  nameValuePair "allow-graylog-nodes-${region}" ({resources, ...}: {
    inherit region accessKeyId;
    _file = ./allow-graylog-nodes.nix;
    description = "Allow Graylog nodes ${region}";
    rules = [{
      protocol = "tcp"; # all
      fromPort = 5044;
      toPort = 5044;
      sourceIp = resources.elasticIPs."${name}-ip";
    }];
  })
)
