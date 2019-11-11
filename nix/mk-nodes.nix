{ targetEnv }:
let
  inherit (import ../nix { }) lib;
  inherit (lib)
    range listToAttrs mapAttrsToList nameValuePair foldl forEach filterAttrs
    recursiveUpdate;

  pp = v: __trace (__toJSON v) v;

  # defs: passed from clusters/jormungandr-$CLUSTER.nix as the node defs
  mkNodes = defs:
    listToAttrs (foldl foldNodes {
      stakeKeys = allStakeKeys;
      nodes = [ ];
    } (mapAttrsToList definitionToNode defs)).nodes;

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

  mkNode = args:
    recursiveUpdate {
      imports = args.imports ++ [ ../modules/common.nix ];
      deployment.targetEnv = targetEnv;
      node.isStake = false;
    } args;

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
          keyFile = ../. + "/static/${file}";
          user = "jormungandr";
        };
      } value;
    };

  allStakeKeys = __attrNames (filterAttrs
    (fileName: _: (__match "^secret_pool_[0-9]+.yaml$" fileName) != null)
    (__readDir ../static));

  nextStakeKey = stakeKeys:
    if __length stakeKeys > 0 then
      __head stakeKeys
    else
      abort "Not enough stake keys for your cluster";

  addStakeKeys = stakeKeys: elems:
    foldl ({ stakeKeys, nodes }: elem:
      let result = addStakeKey stakeKeys elem;
      in {
        nodes = nodes ++ result.nodes;
        inherit (result) stakeKeys;
      })
      { inherit stakeKeys; nodes = [ ]; }
      elems;

  addStakeKey = stakeKeys: elem:
    if elem.value.node.isStake then {
      nodes = [ (addDeploymentKey elem (nextStakeKey stakeKeys)) ];
      stakeKeys = __tail stakeKeys;
    } else {
      nodes = [ elem ];
      inherit stakeKeys;
    };
in mkNodes
