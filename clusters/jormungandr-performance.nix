{ targetEnv, tiny, large }:
let
  inherit (import ../nix { }) lib;
  inherit (lib)
    range listToAttrs mapAttrsToList nameValuePair foldl forEach filterAttrs
    recursiveUpdate;

  nodes = mkNodes {
    monitor = {
      imports = [ tiny ../roles/monitor.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    explorer = {
      imports = [ tiny ../roles/jormungandr-explorer.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    faucet = {
      imports = [ tiny ../roles/jormungandr-faucet.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    stake-ams1 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      amount = 2;
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    relay-ams1 = {
      imports = [ tiny ../roles/jormungandr-relay.nix ];
      amount = 2;
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };
  };

  mkNode = args:
    recursiveUpdate {
      imports = args.imports ++ [ ../modules/common.nix ];
      deployment.targetEnv = targetEnv;
    } args;

  allStakeKeys = __attrNames (filterAttrs
    (fileName: _: (__match "^secret_pool_[0-9]+.yaml$" fileName) != null)
    (__readDir ../static/secrets));

  definitionToNode = name:
    { amount ? null, ... }@args:
    let pass = removeAttrs args [ "amount" ];
    in (if amount != null then
      forEach (range 1 amount)
      (n: nameValuePair "${name}-${toString n}" (mkNode pass))
    else
      nameValuePair name (mkNode pass));

  addDeploymentKey = { name, value }:
    file: {
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
      withKey = if __typeOf elem == "set" then
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
