{ pkgs, lib, ... }: {
  imports = [ ./. ];
  deployment.ec2 = {
    instanceType = "c5.xlarge";
  };
  boot.loader.grub.device = lib.mkForce "/dev/nvme0n1";
}
