let
  sources = import ../nix/sources.nix;
  eval-config = import (sources.nixpkgs + "/nixos/lib/eval-config.nix");
  nixpkgs = sources.nixpkgs;
  pkgs = import ../nix { };
  inherit (pkgs) lib;
  trustedPeers = __fromJSON (__readFile ./trusted_peers.json);
  jormungandrPkgs = pkgs.jormungandrLib.environments.itn_rewards_v1.packages;
in {
  ami = (eval-config {
    system = "x86_64-linux";
    modules = [
      (nixpkgs + "/nixos/maintainers/scripts/ec2/amazon-image.nix")
      {
        imports = [ (sources.jormungandr-nix + "/nixos") ];
        disabledModules = [ "services/networking/jormungandr.nix" ];

        system.extraDependencies = with pkgs; [
          stdenv
          busybox
          jormungandrPkgs.jcli
          janalyze
          sendFunds
          checkTxStatus
        ];

        environment.variables.JORMUNGANDR_RESTAPI_URL = "http://127.0.0.1:3001/api";

        networking.firewall.allowedTCPPorts = [ 3000 ];

        systemd.services.jormungandr = {
          serviceConfig = {
            MemoryMax = "1.9G";
          };
        };

        services.jormungandr = {
          enable = true;
          withBackTraces = true;
          package = jormungandrPkgs.jormungandr;
          jcliPackage = jormungandrPkgs.jcli;
          listenAddress = "/ip4/0.0.0.0/tcp/3000";
          rest.listenAddress = "127.0.0.1:3001";
          logger = {
            level = "info";
            output = "journald";
          };
          inherit trustedPeers;
          maxConnections = 100;
        };
      }
    ];
  }).config.system.build.amazonImage;
}
