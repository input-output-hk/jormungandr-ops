{ ... }:
import ../physical/aws/common.nix {
  cluster = import ../clusters/jormungandr-incentivized.nix {
    targetEnv = "ec2";
    tiny = ../physical/aws/c5.xlarge.nix;
    large = ../physical/aws/t3.xlarge.nix;
  };
}
