{ pkgs, lib, config, nodes, resources, name, deploymentName, ... }:
let
  sources = import ../nix/sources.nix;

  inherit (import ../globals.nix) domain;
  inherit (lib) mapAttrs' hasPrefix listToAttrs attrValues nameValuePair;

  monitoringFor = node:
    let cfg = node.config.node;
    in {
      hasJormungandrPrometheus = cfg.isRelay || cfg.isStake;
      hasNginx = cfg.isFaucet || cfg.isExplorer || cfg.isMonitoring;
    };

  mkMonitoredNodes = suffix:
    mapAttrs'
    (name: node: nameValuePair "${name}${suffix}" (monitoringFor node)) nodes;

  monitoredNodes = {
    ec2 = mkMonitoredNodes "-ip";
    libvirtd = mkMonitoredNodes "";
    packet = mkMonitoredNodes "";
  };

  loadFile = file:
    if __pathExists file then import file else {};

in {
  imports = [
    ../modules/monitoring-services.nix
    ../modules/common.nix
    ../modules/monitoring-alerts.nix
  ];

  node.fqdn = "${name}.${domain}";

  deployment.ec2.securityGroups = [
    resources.ec2SecurityGroups."allow-public-www-https-${config.node.region}"
  ];

  services.monitoring-services = {
    enable = true;
    webhost = config.node.fqdn;
    enableACME = config.deployment.targetEnv != "libvirtd";
    extraHeader = "Deployment Name: ${deploymentName}<br>";

    deadMansSnitch = loadFile ../secrets/dead-mans-snitch.nix;
    grafanaCreds = loadFile ../secrets/grafana-creds.nix;
    graylogCreds = loadFile ../secrets/graylog-creds.nix;
    oauth = loadFile ../secrets/oauth.nix;
    pagerDuty = loadFile ../secrets/pager-duty.nix;

    monitoredNodes = monitoredNodes.${config.deployment.targetEnv};

    applicationDashboards =
      [ (sources.jormungandr-nix + "/nixos/jormungandr-monitor/grafana.json") ];
  };

  systemd.services.graylog.environment.JAVA_OPTS = ''
    -Djava.library.path=${pkgs.graylog}/lib/sigar -Xms3g -Xmx3g -XX:NewRatio=1 -server -XX:+ResizeTLAB -XX:+UseConcMarkSweepGC -XX:+CMSConcurrentMTEnabled -XX:+CMSClassUnloadingEnabled -XX:+UseParNewGC -XX:-OmitStackTraceInFastThrow
  '';

  services.elasticsearch.extraJavaOptions = [ "-Xms6g" "-Xmx6g" ];
  services.zfs.trim.enabled = true;
}
