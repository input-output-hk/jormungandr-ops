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
  stakes = filterAttrs (name: node: node.node.isStake) machines;
  relays = filterAttrs (name: node: node.node.isRelay) machines;
  string = toString (attrNames machines);
  stakeStrings = toString (attrNames stakes);
  json = toJSON (attrNames machines);
}
