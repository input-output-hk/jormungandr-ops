{ }:
let inherit (builtins) typeOf trace attrNames toString toJSON;
in { pp = v: trace (toJSON v) v; }
