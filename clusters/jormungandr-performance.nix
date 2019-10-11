{ tiny, large }:
let
  inherit (import ../nix { }) lib;
  inherit (lib)
    range listToAttrs mapAttrsToList nameValuePair foldl forEach filterAttrs recursiveUpdate;

  nodes = mkNodes {
    monitor = {
      size = large;
      role = ../roles/monitor.nix;
    };

    explorer = { role = ../roles/jormungandr-explorer.nix; };

    faucet = { role = ../roles/jormungandr-faucet.nix; };

    stake-euc1 = {
      amount = 2;
      region = "eu-central-1";
      role = ../roles/jormungandr-stake.nix;
    };

    stake-use1 = {
      amount = 2;
      region = "us-east-1";
      role = ../roles/jormungandr-stake.nix;
    };

    relay-euc1 = {
      amount = 2;
      region = "eu-central-1";
      role = ../roles/jormungandr-relay.nix;
    };

    relay-use1 = {
      amount = 2;
      region = "us-east-1";
      role = ../roles/jormungandr-relay.nix;
    };
  };

  mkNode = { size ? tiny, region, role, ... }: {
    imports = [ size role ../modules/common.nix ];
    deployment.ec2.region = region;
  };

  allStakeKeys = __attrNames (filterAttrs
    (fileName: _: (__match "^secret_pool_[0-9]+.yaml$" fileName) != null)
    (__readDir ../static/secrets));

  definitionToNode = name:
    { amount ? null, region ? "eu-central-1", ... }@givenArgs:
    let args = { inherit region; } // givenArgs;
    in (if amount != null then
      forEach (range 1 amount)
      (n: nameValuePair "${name}-${toString n}" (mkNode args))
    else
      nameValuePair name (mkNode args));

  addDeploymentKey = {name, value}: file:
  {
    inherit name;
    value = recursiveUpdate {
      deployment.keys."secret_pool.yaml" = {
        keyFile = ../. + "/static/secrets/${file}";
        user = "jormungandr";
      };
    } value;
  };

  nextStakeKey = stakeKeys:
    if __length stakeKeys > 0 then
      __head stakeKeys
    else
      abort "Not enough stake keys for your cluster";

  addStakeKeys = stakeKeys: elems:
    foldl ({ stakeKeys, nodes }:
      elem:
      if (__match "^stake-.*$" elem.name) != null then {
        nodes = nodes ++ [ (addDeploymentKey elem (nextStakeKey stakeKeys)) ];
        stakeKeys = __tail stakeKeys;
      } else {
        nodes = nodes ++ [ elem ];
        inherit stakeKeys;
      }) {
        inherit stakeKeys;
        nodes = [ ];
      } elems;

  addStakeKey = stakeKeys: elem:
    if (__match "^stake-.*$" elem.name) != null then {
      nodes = [ (addDeploymentKey elem (nextStakeKey stakeKeys)) ];
      stakeKeys = __tail stakeKeys;
    } else {
      nodes = [ elem ];
      inherit stakeKeys;
    };

  foldNodes = { stakeKeys, nodes }:
    elem:
    let
      withKey = 
        if __typeOf elem == "set" then
          addStakeKey stakeKeys elem
        else
          addStakeKeys stakeKeys elem;
      in {
        inherit (withKey) stakeKeys;
        nodes = nodes ++ withKey.nodes;
      };

  mkNodes = defs:
    listToAttrs (foldl foldNodes {
      stakeKeys = allStakeKeys;
      nodes = [ ];
    } (mapAttrsToList definitionToNode defs)).nodes;
in {
  network.description = "jormungandr-performance";
  network.enableRollback = true;
} // nodes
