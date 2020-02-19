{ ... }:
import ../physical/aws/common.nix {
  cluster = import ../clusters/jormungandr-incentivized.nix {
    targetEnv = "ec2";
    tiny = ../physical/aws/t3a.large.nix;
    large = ../physical/aws/t3.xlarge.nix;
  };
}
