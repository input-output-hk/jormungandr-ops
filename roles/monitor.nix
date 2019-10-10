{pkgs, ...}: {
  imports = [
    ../modules/monitoring-services.nix
  ];
  services.monitoring-services = {
    enable = true;
    webhost = "monitor";
    enableACME = false;

    grafanaCreds = {
      user = "changeme";
      password = "changeme";
    };

    graylogCreds = {
      user = "root";
      password = "Exu4Abo4rae0reixeet9pha9ed7OhQui";
      clusterSecret = "ts22dTBqj0NVcg87LO6yGQOkdoFOkL1qbpr9b2A9bBVMoBu62S3bWkh44cUXHOYCWKwrcuhiOnE8na4zcgxxFrP2AKRcrncV";
      passwordHash = "4612d4ce0a3ffa9bbc83046208fd7410622dc29657e242c8bd18d10efdb79fd5";
    };

    oauth = {
      clientID = "performance";
      clientSecret = "performance";
      cookie.secret = "veelad4eith9Veiw";
      emailDomain = "iohk.io";
    };
  };

  systemd.services.graylog.environment.JAVA_OPTS = ''
    -Djava.library.path=${pkgs.graylog}/lib/sigar -Xms1g -Xmx1g -XX:NewRatio=1 -server -XX:+ResizeTLAB -XX:+UseConcMarkSweepGC -XX:+CMSConcurrentMTEnabled -XX:+CMSClassUnloadingEnabled -XX:+UseParNewGC -XX:-OmitStackTraceInFastThrow
  '';

  services.elasticsearch.extraJavaOptions = [ "-Xms1g" "-Xmx1g" ];
}
