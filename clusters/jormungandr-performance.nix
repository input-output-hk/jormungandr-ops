{ targetEnv, tiny, large }:
let
  mkNodes = import ../nix/mk-nodes.nix {};

  nodes = mkNodes {
    monitor = {
      imports = [ tiny ../roles/monitor.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    explorer = {
      imports = [ tiny ../roles/jormungandr-explorer.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    faucet = {
      imports = [ tiny ../roles/jormungandr-faucet.nix ];
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    stake-ams1 = {
      imports = [ tiny ../roles/jormungandr-stake.nix ];
      amount = 4;
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };

    relay-ams1 = {
      imports = [ tiny ../roles/jormungandr-relay.nix ];
      amount = 4;
      deployment.ec2.region = "eu-central-1";
      deployment.packet.facility = "ams1";
    };
  };
in {
  network.description = "jormungandr-performance";
  network.enableRollback = true;
} // nodes
