let
  inherit (builtins) getEnv removeAttrs toString toJSON attrNames;
  inherit ((import ../nix { }).lib) filterAttrs;

  globals = import ./globals.nix;
  nixopsDeployment = getEnv "NIXOPS_DEPLOYMENT";
  deployment = import (../deployments + "/${nixopsDeployment}.nix") { };

in rec {
  inherit (deployment) resources;

  machines = removeAttrs deployment [ "resources" "monitoring" "network" ];
  all = removeAttrs deployment [ "resources" "network" ];

  initalResourcesNames = __concatLists (map __attrNames
    (__attrValues (builtins.removeAttrs resources [ "elasticIPs" ])));

  stakes = filterAttrs (name: node: node.node.isStake or false) machines;
  relays = filterAttrs (name: node:
    node.node.isRelay or node.node.isExplorer or node.node.isFaucet or false)
    machines;

  allNames = __attrNames all;
  allStrings = toString allNames;

  stakesNames = __attrNames stakes;
  stakeStrings = toString stakesNames;

  relaysNames = __attrNames relays;
  relayStrings = toString relaysNames;

  string = toString (attrNames machines);
  json = toJSON (attrNames machines);
}
