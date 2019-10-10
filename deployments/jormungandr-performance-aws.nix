let
  region = "eu-central-1";
  accessKeyId = let value = __getEnv "AWS_ACCESS_KEY_ID";
  in if value == "" then
    (abort "AWS_ACCESS_KEY_ID environment variable is not set")
  else
    value;

  cluster = import ../clusters/jormungandr-performance.nix {
    xlarge = ../physical/aws/t3.xlarge.nix;
    tiny = ../physical/aws/t2.nano.nix;
  };

  settings = {
    resources = {
      region = "eu-central-1";

      ec2KeyPairs = {
        "jormungandr-${region}" = { inherit region accessKeyId; };
      };

      ec2SecurityGroups = {
        "allow-all-ssh-${region}" = _: {
          _file = ./jormungandr-performance-aws.nix;
          inherit region accessKeyId;
          description = "SSH";
          rules = [{
            protocol = "tcp";
            fromPort = 22;
            toPort = 22;
            sourceIp = "0.0.0.0/0";
          }];
        };

        "allow-deployer-ssh-${region}" = _: {
          inherit region accessKeyId;
          _file = ./jormungandr-performance-aws.nix;
          description = "SSH";
          rules = [{
            protocol = "tcp";
            fromPort = 22;
            toPort = 22;
            sourceIp = "0.0.0.0/0"; # FIXME: IP of deployer
          }];
        };
      };
    };
  };
in cluster // settings
