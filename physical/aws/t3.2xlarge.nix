{ pkgs, lib, ... }: {
  imports = [ ./. ];
  deployment.ec2 = {
    instanceType = "t3.2xlarge";
  };
  boot.loader.grub.device = lib.mkForce "/dev/nvme0n1";
}
