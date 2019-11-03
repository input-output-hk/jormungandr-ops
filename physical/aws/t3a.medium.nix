{ pkgs, lib, ... }: {
  imports = [ ./. ];
  deployment.ec2.instanceType = "t3a.medium";
  boot.loader.grub.device = lib.mkForce "/dev/nvme0n1";
}
