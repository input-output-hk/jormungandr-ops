{ pkgs, lib, ... }: {
  services.monitoring-services.applicationRules = [
    {
      alert = "jormungandr_block_divergence";
      expr = "max(jormungandr_lastBlockHeight) - ignoring(alias,instance,job,role) group_right(instance) jormungandr_lastBlockHeight > 20";
      for = "30m";
      labels = {
        severity = "page";
      };
      annotations = {
        summary = "{{$labels.alias}}: Jormungandr block divergence detected";
        description = "{{$labels.alias}}: Jormungandr block divergence detected for more than 30 minutes and 20 blocks";
      };
    }
    {
      alert = "jormungandr_blockheight_unchanged";
      expr = "rate(jormungandr_lastBlockHeight[5m]) == 0";
      for = "30m";
      labels.severity = "page";
      annotations = {
        summary = "{{$labels.alias}} Jormungandr blockheight unchanged";
        description = "{{$labels.alias}} Jormungandr blockheight unchanged for >=30mins.";
      };
    }
    {
      alert = "jormungandr_faucetFunds_monitor";
      expr = ''(jormungandr_address_funds{alias=~"faucet.*"} / 1e6) < 5000000'';
      for = "5m";
      labels.severity = "page";
      annotations = {
        summary = "{{$labels.alias}} Jormungandr faucet wallet balance low alert";
        description = "{{$labels.alias}} Jormungandr faucet wallet balance is low (< 5M ADA)";
      };
    }
    {
      alert = "prometheus WAL corruption";
      expr = "(rate(prometheus_tsdb_wal_corruptions_total[5m]) OR on() vector(1)) > 0";
      for = "5m";
      labels.severity = "page";
      annotations = {
        summary = "{{$labels.alias}} Prometheus WAL corruption alert";
        description = "{{$labels.alias}} Prometheus WAL corruption total is changing or a no data condition has been detected";
      };
    }
  ];
}
