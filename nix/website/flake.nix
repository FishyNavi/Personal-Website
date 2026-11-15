{
  description = "Basic Website Host Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {self, nixpkgs}:
  let
    system = "x86_64-linux";
  in
  {
    nixosModules.default = { config, lib, ...}:
      let
        cfg = config.services.personalWebsite;
      in
      {
        options.services.personalWebsite = {
          enable = lib.mkEnableOption "Enable website";
          domain = lib.mkOption {
            type = lib.types.str;
            description = "Nginx virtualHost domain";
          };
        };
        config = lib.mkIf cfg.enable {
          users.users.astro = {
            isSystemUser = true;
            group = "astro";
            home = "/var/www/astro/";
            createHome = true;
          };
          users.groups.astro = {};
          services.nginx.virtualHosts.${cfg.domain} = {
            listen = [{ addr = "0.0.0.0"; port = 80; }];
              globalRedirect = null;
              enableACME = true;
              root = "/var/www/dist/";
              locations."/" = {
                index = "index.html";
                extraConfig = ''
                  try_files $uri $uri/ $uri.html /index.html;
                  absolute_redirect off;
                '';
              };
            };
          };
        };
  };
}
