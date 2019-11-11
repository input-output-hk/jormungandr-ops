let
  inherit (builtins) getEnv removeAttrs toString toJSON attrNames;
  inherit ((import ../nix {}).lib) filterAttrs;

  globals = import ./globals.nix;
  nixopsDeployment = getEnv "NIXOPS_DEPLOYMENT";
  deployment = import (../deployments + "/${nixopsDeployment}.nix") {};

  ignore = [
    "resources"
    "monitoring"
    "network"
  ];

in rec {
  machines = removeAttrs deployment ignore;
  inherit (deployment) resources;

  initalResourcesNames = __concatLists (
    map __attrNames (
      __attrValues (builtins.removeAttrs resources ["elasticIPs"])
    )
  );

  stakes = filterAttrs (name: node:
    node.node.isStake or false) machines;
  relays = filterAttrs (name: node:
    node.node.isRelay or node.node.isExplorer or node.node.isFaucet or false) machines;

  stakesNames = __attrNames stakes;
  relaysNames = __attrNames relays;
  string = toString (attrNames machines);
  stakeStrings = toString (attrNames stakes);
  json = toJSON (attrNames machines);
}
