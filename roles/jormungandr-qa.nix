{ config, lib, resources, name, pkgs, ... }:
let sources = import ../nix/sources.nix;
  inherit (import ../globals.nix) domain;
  sshKeys =
    import ((import ../nix/sources.nix).iohk-ops + "/lib/ssh-keys.nix") {
      inherit lib;
    };
  inherit (sshKeys) allKeysFrom devOps;
  devOpsKeys = allKeysFrom devOps;
  qaKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA2uXZKJ+zgWyRBecpLuDhy5t4cR8X/kcWc+fN91QuCyTVTdmWt0Y2caSIzVXg4ZhIpfWV3x/y/daKbdPdVnF5WCRnZHrgUGkXg4SPyzw2eAgiR0IZPMhq38xB5hwGRHl7XiRtD0saQrk7w0aDk17bB4kuosA84zVqks+LZUaSqLnCL2YQsMbQBCWoMIl9HvdgHH1coG3gwoDQE0xnx7+8LszjkCUoXr/OpW/2Dlzhb8zHm7Ed9R7bDSQqUtdltTDFKA4n6BeWbxJTi5kPw+O4sfk4V1p0UVK7mSkHwymj0kaE3ANvafHXYW9Dl79+iHgMts3gcgXxvpDBNKNvLN2STw== dorin.solomon@iohk.io"
  ];
in {
  imports = [ ../modules/common.nix ];
  deployment.ec2.securityGroups = [
    resources.ec2SecurityGroups."allow-ssh-${config.node.region}"
  ];

  # environment.systemPackages = with pkgs; [ ];
  users.users."qa" = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = devOpsKeys ++ qaKeys;
  };
}
