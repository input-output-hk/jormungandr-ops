self: super:
let ngx_healthcheck_module =
        super.fetchFromGitHub {
          owner = "josephmilla";
          repo = "ngx_healthcheck_module";
          rev = "f1a1ac1d6074cce19361b3b0c460e9a079520a6d";
          sha256 = "084vapd6gw9y5mrvsly2nxbvnnpxpd0fi7kqqh6d3g7mdx17mahs";
        };
in {
  nginxMainline = super.nginxMainline.override
    (oldAttrs: { modules = oldAttrs.modules ++ [ super.nginxModules.vts ]; });

  nginxStable = super.nginxStable.override (previous: {
    modules = previous.modules ++ [
      super.nginxModules.vts
      {
        src = ngx_healthcheck_module;
        patches = [
          "${ngx_healthcheck_module}/nginx_healthcheck_for_nginx_1.16+.patch"
        ];
      }
    ];
  });
}
