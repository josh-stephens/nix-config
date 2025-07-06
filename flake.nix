{
  description = "My nix config";

  inputs = {
    # Nixpkgs - using unstable as primary
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11"; # Keep stable available if needed

    # Darwin
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim Nightly
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";

    # Hardware-specific optimizations
    hardware.url = "github:nixos/nixos-hardware/master";
  };

  outputs = { nixpkgs, darwin, home-manager, self, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;

      # Only the systems we actually use
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = f: lib.genAttrs systems f;

      # Common special arguments for all configurations
      mkSpecialArgs = system: {
        inherit inputs outputs;
      };
    in
    {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );

      overlays = import ./overlays { inherit inputs; };

      # NixOS configurations
      nixosConfigurations = {
        # Add NixOS systems here when needed
        # example = lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = [ ./hosts/example ];
        # };
      };

      # Darwin configurations
      darwinConfigurations = {
        # Add macOS systems here when needed
        # example = darwin.lib.darwinSystem {
        #   system = "aarch64-darwin";
        #   modules = [ ./hosts/example ];
        # };
      };

      # Home configurations - for standalone home-manager
      homeConfigurations = 
        let
          mkHome = { system, username, hostname }: home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ outputs.overlays.default ];
              config.allowUnfree = true;
            };
            extraSpecialArgs = mkSpecialArgs system // { inherit hostname; };
            modules = [ 
              ./home-manager/hosts/${hostname}.nix 
              {
                home = {
                  inherit username;
                  homeDirectory = if lib.hasSuffix "darwin" system 
                    then "/Users/${username}"
                    else "/home/${username}";
                };
              }
            ];
          };
        in {
          # Add your configurations here
          # Format: "username@hostname"
          "josh@bishop" = mkHome { 
            system = "x86_64-linux"; 
            username = "josh";
            hostname = "bishop";
          };
          
          # Example for adding more machines:
          # "youruser@yourhostname" = mkHome {
          #   system = "x86_64-linux";  # or "aarch64-darwin" for Mac
          #   username = "youruser";
          #   hostname = "yourhostname";
          # };
        };
    };
}