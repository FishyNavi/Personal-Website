{
  description = "Basic Nepenthes Tarpit Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {self, nixpkgs}:
  let system = "x86_64-linux";
  pkgs = nixpkgs.legacyPackages.${system};

  nepenthesSrc = pkgs.fetchFromGitHub {
    owner = "NEPENTHESWEB";
    repo = "NEPENTHES-py";
    rev = "main";
    hash = "sha256-NUlFV4lbCuHteO9y2sKI4G4+gC+I2afhu7anwDob37k=";
  };
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    aiohttp
    pyyaml
    jinja2
  ]);

  nepenthesPkg = pkgs.writeShellScriptBin "nepenthes" ''
    CONFIG_FILE="''${1:-./config.yml}"
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" <<EOF
    http_host: "127.0.0.1"
    http_port: 8893
    templates:
        - "${nepenthesSrc}/templates"
    seed_file: "./seed.txt"
    min_wait: 10
    max_wait: 65
    silos:
        - name: default
        default: true
        corpus: "${nepenthesSrc}/corpus/sample.txt"
        wordlist: "${nepenthesSrc}/corpus/words.txt"
        prefixes:
            - /trap
        redirect_rate: 5
        bogon_filter: true
    EOF
    fi
    PYTHONPATH="${nepenthesSrc}" exec ${pythonEnv}/bin/python -m nepenthes "$CONFIG_FILE"
  '';
  in
  {
    packages.${system}.default = nepenthesPkg;
    nixosModules.default = { config, lib, ...}:
      let
        cfg = config.services.nepenthes;
      in
      {
        options.services.nepenthes = {
          enable = lib.mkEnableOption "Nepenthes Crawler Tarpit";
          domain = lib.mkOption {
            type = lib.types.str;
            description = "Nginx virtualHost domain";
          };
          path = lib.mkOption {
            type = lib.types.str;
            default = "/trap/";
            description = "Tarpit url path";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8893;
            description = "Nepenthes local port";
          };
        };
        config = lib.mkIf cfg.enable {
          users.users.nepenthes = {
            isSystemUser = true;
            group = "nepenthes";
            home = "/var/lib/nepenthes/";
            createHome = true;
          };
          users.groups.nepenthes = {};
          systemd.services.nepenthes = {
            description = "Nepenthes Crawler Tarpit";
            after = ["network.target"];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              User = "nepenthes";
              Group = "nepenthes";
              WorkingDirectory = "/var/lib/nepenthes";
              ExecStart = "${nepenthesPkg}/bin/nepenthes /var/lib/nepenthes/config.yml";
              Restart = "always";
            };
          };
          services.nginx.virtualHosts.${cfg.domain}.locations.${cfg.path} = {
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
            extraConfig = ''
              proxy_set_header X-Prefix '${cfg.path}';
              proxy_set_header X-Forwarded-For $remote_addr;
              proxy_buffering off;
            '';
          };
        };
      };
  };
}
