{ ... }@args:
let pp = v: __trace (__toJSON v) v;
in import ../physical/aws/common.nix {
  cluster = import ../clusters/jormungandr-nightly.nix {
    targetEnv = "ec2";
    large = ../physical/aws/t3a.large.nix;
    xlarge = ../physical/aws/r5a.xlarge.nix;
    xlarge-monitor = ../physical/aws/r5a.xlarge-monitor.nix;
  };
  args = pp args;
}
