self: super:
let inherit (builtins) typeOf trace attrNames toString toJSON;
in {
  packages = { pp = v: trace (toJSON v) v; };
}
