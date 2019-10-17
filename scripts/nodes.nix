with builtins;

let
  globals = import ./globals.nix;
  nixopsDeployment = getEnv("NIXOPS_DEPLOYMENT");
  deployment = import (../deployments + "/${nixopsDeployment}.nix") {};

  ignore = [
    "resources"
    "monitoring"
    "network"
  ];

  machines = removeAttrs deployment ignore;
in {
  string = toString (attrNames machines);
  json = toJSON (attrNames machines);
}
