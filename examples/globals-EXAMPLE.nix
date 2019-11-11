# This is an example file for `globals.nix` that should live in the root dir
let
  inherit (builtins) attrNames filter removeAttrs getEnv toJSON trace;
  inherit ((import ./nix).lib) hasPrefix;

  requireEnv = name:
    let value = getEnv name;
    in if value == "" then
      abort "${name} environment variable is not set"
    else
      value;
in rec {
  deployment = requireEnv "NIXOPS_DEPLOYMENT";
  zone = "jormungandr-testnet.iohkdev.io";
  domain = "$SUBSUBDOMAIN.${zone}";

  deployerIp = "A.B.C.D";

  packet = {
    inherit zone domain;

    credentials = {
      accessKeyId = requireEnv "PACKET_API_KEY";
      project = requireEnv "PACKET_PROJECT_ID";
    };
  };

  ec2 = {
    inherit zone domain;

    credentials.accessKeyId = requireEnv "AWS_ACCESS_KEY_ID";
  };
}
