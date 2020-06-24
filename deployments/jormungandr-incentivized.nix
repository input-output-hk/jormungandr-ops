{ ... }:
import ../physical/aws/common.nix {
  cluster = import ../clusters/jormungandr-incentivized.nix {
    targetEnv = "ec2";
    t3a-large = ../physical/aws/t3a.large.nix;
    t3-xlarge = ../physical/aws/t3.xlarge.nix;
    t3-2xlarge = ../physical/aws/t3.2xlarge.nix;
  };
}
