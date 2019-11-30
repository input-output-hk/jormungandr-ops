{ pkgs, lib, ... }: {
  imports = [ ./. ];
  deployment.ec2 = {
    instanceType = "r5a.xlarge";
    ebsInitialRootDiskSize = 1000;
    associatePublicIpAddress = true;
  };
  boot.loader.grub.device = lib.mkForce "/dev/nvme0n1";
}
