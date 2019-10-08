{ nodes, ... }: {
  imports = [ ../modules/jormungandr.nix ];
  services.jormungandr = {
    block0 = ../static/block-0.bin;
    secrets-paths = [ "/run/keys/secret_pool.yaml" ];
    topicsOfInterest = {
      messages = "high";
      blocks = "high";
    };
  };

  users.users.jormungandr.extraGroups = [ "keys" ];

  systemd.services."jormungandr" = {
    after = [ "pool_secret.yaml-key.service" ];
    wants = [ "pool_secret.yaml-key.service" ];
  };
}
