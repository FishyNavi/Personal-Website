{
  description = "Basic Website Host Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nepenthes.url = "path:../nepenthes";
  };

  outputs = { self, nixpkgs, nepenthes, ... }: {
    nixosModules.default = { config, pkgs, lib, ... }:
      let
        cfg = config.services.personal-website;
      in
      {
        imports = [
          nepenthes.nixosModules.default
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
            home = "/var/www/astro";
            createHome = true;
          };
          users.groups.astro = {};

          security.sudo.extraRules = [
            {
              users = [ "astro" ];
              commands = [
                {
                  command = "/run/current-system/sw/bin/systemctl restart personal-website-server.service";
                  options = [ "NOPASSWD" ];
                }
              ];
            }
          ];

          systemd.services.personal-website-server = {
            description = "Astro SSR Node Server";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            path = with pkgs; [ gawk coreutils ];
            serviceConfig = {
              User = "astro";
              Group = "astro";
              WorkingDirectory = "/var/www/astro/repo/website";
              ExecStart = "${pkgs.nodejs_22}/bin/node /var/www/astro/repo/website/dist/server/entry.mjs";
              Restart = "always";
              RestartSec = "5s";
              Environment = [
                "HOST=127.0.0.1"
                "PORT=4321"
              ];
            };
          };

          # 2. Git Fetch & Rebuild Service
          systemd.services.personal-website = {
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            path = with pkgs; [ git nodejs_22 bash "/run/wrappers" ];

            serviceConfig = {
              Type = "oneshot";
              User = "astro";
              Group = "astro";
              WorkingDirectory = "/var/www/astro";
            };

            script = ''
              set -e
              REPO_DIR="/var/www/astro/repo"
              APP_DIR="$REPO_DIR/website"

              if [ ! -d "$REPO_DIR/.git" ]; then
                git clone --branch ${cfg.branch} ${cfg.repoUrl} "$REPO_DIR"
                cd "$APP_DIR"
                npm install
                npm run build
                sudo /run/current-system/sw/bin/systemctl restart personal-website-server.service
                exit 0
              fi

              cd "$REPO_DIR"
              git fetch origin ${cfg.branch}

              LOCAL=$(git rev-parse HEAD)
              REMOTE=$(git rev-parse FETCH_HEAD)
              if [ "$LOCAL" != "$REMOTE" ]; then
                git reset --hard FETCH_HEAD
                cd "$APP_DIR"
                npm install
                npm run build
                sudo /run/current-system/sw/bin/systemctl restart personal-website-server.service
              fi
            '';
          };

          # 3. Timer to check for Git updates every 5 minutes
          systemd.timers.personal-website = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "5m";
              OnUnitActiveSec = "5m";
              Unit = "personal-website.service";
            };
          };

          # 4. Nginx Reverse Proxy to Astro Node Server
          services.nginx.virtualHosts.${cfg.domain} = {
            listen = [{ addr = "0.0.0.0"; port = 80; }];
            globalRedirect = null;
            enableACME = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:4321";
              proxyWebsockets = true;
            };
          };
        };
      };
  };
}
