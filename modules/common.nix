{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ bashInteractive lsof tree bat jq ];
}
