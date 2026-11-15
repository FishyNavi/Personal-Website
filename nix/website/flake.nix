{
  description = "Basic Website Host Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nepenthes.url = "path:./nepenthes";
  };

  outputs = {self, nixpkgs, nepenthes, ...}:
  let
    system = "x86_64-linux";
  in
  {
    nixosModules.default = { config, pkgs, lib, ...}:
      let
        cfg = config.services.personal-website;
      in
      {

        imports = [
          nepenthes.nixosModules.default;
        ];
        options.services.personal-website = {
          enable = lib.mkEnableOption "Enable website";
          domain = lib.mkOption {
            type = lib.types.str;
            description = "Nginx virtualHost domain";
          };
          repoUrl = lib.mkOption {
            type = lib.types.str;
            description = "Git repo url";
          };
          branch = lib.mkOption {
            type = lib.types.str;
            default = "main";
            description = "Git branch";
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

          systemd.tmpfiles.rules = [
            "d /var/www/dist 0755 astro astro -"
          ];

          systemd.services.personal-website = {
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            path = with pkgs; [ git nodejs rsync bash ];

            serviceConfig = {
              Type = "oneshot";
              User = "astro";
              Group = "astro";
              WorkingDirectory = "/var/www/astro";
            };

            script = ''
              set -e
              REPO_DIR="/var/www/astro/repo"
              DIST_DIR="/var/www/dist"

              if [ ! -d "$REPO_DIR/.git" ]; then
                git clone --branch ${cfg.branch} ${cfg.repoUrl} "$REPO_DIR"
                cd "$REPO_DIR"
                npm ci
                npm run build
                rsync -a --delete dist/ "$DIST_DIR"
                exit 0
              fi

              cd "$REPO_DIR"
              git fetch origin ${cfg.branch}

              LOCAL=$(git rev-parse HEAD)
              REMOTE=$(git rev-parse origin/${cfg.branch})
              if [ "$LOCAL" != "$REMOTE" ]; then
                git reset --hard origin/${cfg.branch}
                npm ci
                npm run build --release
                rsync -a --delete dist/ "$DIST_DIR"
              fi
            '';
          };

          systemd.timers.personal-website = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "5m";
              OnUnitActiveSec = "5m";
              Unit = "personal-website.service";
            };
          };

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
