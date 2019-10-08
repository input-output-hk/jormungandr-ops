{ pkgs, ... }: {
  deployment.targetEnv = "libvirtd";
  deployment.libvirtd = {
    headless = true;
    memorySize = 128;
  };
  environment.systemPackages = with pkgs; [ bashInteractive lsof tree bat ];
}
