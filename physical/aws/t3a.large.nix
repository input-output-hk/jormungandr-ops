{ pkgs, lib, ... }: {
  imports = [ ./. ];
  deployment.ec2.instanceType = "t3a.large";
  boot.loader.grub.device = lib.mkForce "/dev/nvme0n1";
}
