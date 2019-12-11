{ sources ? import ./sources.nix, system ? __currentSystem }:
with {
  overlay = self: super: {
    inherit (import sources.niv { }) niv;
    inherit (import sources.cardano-wallet { gitrev = sources.cardano-wallet.rev; }) cardano-wallet-jormungandr;
    packages = self.callPackages ./packages.nix { };
    inherit (import sources.iohk-nix { }) jormungandrLib;
    jormungandrEnv = self.jormungandrLib.environments.${self.globals.environment};
    globals = import ../globals.nix;

    inherit ((import sources.jormungandr-nix { inherit (self.globals) environment; }).scripts)
      janalyze sendFunds delegateStake createStakePool checkTxStatus;
    inherit (self.jormungandrEnv.packages) jormungandr jcli;

    nixops = (import (sources.nixops-core + "/release.nix") {
      nixpkgs = super.path;
      p = (p:
        let
          pluginSources = with sources; [ nixops-packet nixops-libvirtd ];
          plugins = map (source: p.callPackage (source + "/release.nix") { })
            pluginSources;
        in [ p.aws ] ++ plugins);
    }).build.${system};
  };
};
import sources.nixpkgs {
  overlays = [ overlay ];
  inherit system;
  config = { };
}
