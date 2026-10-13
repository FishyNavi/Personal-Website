{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs = inputs:{
    devShells = builtins.mapAttrs(system: pkgs: {	
      default = pkgs.mkShell{
	buildInputs = with pkgs; [
	  static-web-server
	  minify
	  prettier
	  nodejs_22
	  ];
	shellHook = ''
	  echo "meow meow!"
	'';
	};
    }) inputs.nixpkgs.legacyPackages;

  };
}
