{ }:
let inherit (builtins) typeOf trace attrNames toString toJSON;
in {
  pp = v: trace (toJSON v) v;
  requireEnv = name:
    let value = __getEnv name;
    in if value == "" then
      abort "${name} environment variable is not set"
    else
      value;
}
