{ pkgs, ... }: {
  imports = [ ./. ];
  deployment.ec2 = {
    instanceType = "t3.xlarge";
    ebsInitialRootDiskSize = 1000;
    associatePublicIpAddress = true;
  };
}
