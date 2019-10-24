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
        summary = "{{$labels.alias}}: Jormungandr block divergence detected for more than 5 minutes";
        description = "{{$labels.alias}}: Jormungandr block divergence detected for more than 5 minutes";
      };
    }
    {
      alert = "jormungandr_blockheight_unchanged";
      expr = "rate(jormungandr_lastBlockHeight[5m]) == 0";
      for = "30m";
      #for = "10m";
      labels.severity = "page";
      annotations = {
       summary = "{{$labels.alias}} Jormungandr blockheight unchanged for >=30mins";
        description = "{{$labels.alias}} Jormungandr blockheight unchanged for >=30mins.";
        #summary = "{{$labels.alias}} Jormungandr blockheight unchanged for >=10mins";
        #description = "{{$labels.alias}} Jormungandr blockheight unchanged for >=10mins.";
      };
    }
    {
      alert = "jormungandr_faucetFunds_monitor";
      expr = "jormungandr_faucetFunds < 5000000000000";
      #expr = "jormungandr_faucetFunds < 10000000000000";
      for = "5m";
      labels.severity = "page";
      annotations = {
        description = "{{$labels.alias}} Jormungandr faucet wallet balance is low (< 5M ADA)";
        #description = "{{$labels.alias}} Jormungandr faucet wallet balance is low (< 10M ADA)";
      };
    }
    {
      alert = "prometheus WAL corruption";
      expr = "(rate(prometheus_tsdb_wal_corruptions_total[5m]) OR on() vector(1)) > 0";
      for = "5m";
      labels.severity = "page";
      annotations = {
        description = "{{$labels.alias}} Prometheus WAL corruption total is changing or a no data condition has been detected";
      };
    }
  ];
}
