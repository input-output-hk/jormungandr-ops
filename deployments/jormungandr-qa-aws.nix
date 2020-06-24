{ ... }@args:
let pp = v: __trace (__toJSON v) v;
in import ../physical/aws/common.nix {
  cluster = import ../clusters/jormungandr-qa.nix {
    targetEnv = "ec2";
    tiny = ../physical/aws/t3a.medium.nix;
    medium = ../physical/aws/t3a.large.nix;
    large = ../physical/aws/t3.xlarge.nix;
  };

  args = pp args;
}
