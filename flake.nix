{
  description = "Josh Symonds' nix config";

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

      # NixOS configurations - inlined for clarity
      nixosConfigurations = {
        ultraviolet = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = mkSpecialArgs "x86_64-linux";
          modules = [
            ./hosts/ultraviolet
            ./hosts/common.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.joshsymonds = import ./home-manager/headless-x86_64-linux.nix;
              home-manager.extraSpecialArgs = mkSpecialArgs "x86_64-linux";
            }
          ];
        };
        
        bluedesert = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = mkSpecialArgs "x86_64-linux";
          modules = [
            ./hosts/bluedesert
            ./hosts/common.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.joshsymonds = import ./home-manager/headless-x86_64-linux.nix;
              home-manager.extraSpecialArgs = mkSpecialArgs "x86_64-linux";
            }
          ];
        };
        
        echelon = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = mkSpecialArgs "x86_64-linux";
          modules = [
            ./hosts/echelon  # Fixed: was using bluedesert
            ./hosts/common.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.joshsymonds = import ./home-manager/headless-x86_64-linux.nix;
              home-manager.extraSpecialArgs = mkSpecialArgs "x86_64-linux";
            }
          ];
        };
      };

      # Darwin configuration - inlined for clarity
      darwinConfigurations = {
        cloudbank = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = mkSpecialArgs "aarch64-darwin";
          modules = [
            ./hosts/cloudbank
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.joshsymonds = import ./home-manager/aarch64-darwin.nix;
              home-manager.extraSpecialArgs = mkSpecialArgs "aarch64-darwin";
            }
          ];
        };
      };

      # Simplified home configurations - generated programmatically
      homeConfigurations = 
        let
          mkHome = { system, module }: home-manager.lib.homeManagerConfiguration {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
            extraSpecialArgs = mkSpecialArgs system;
            modules = [ module ];
          };
          
          linuxHosts = [ "ultraviolet" "bluedesert" "echelon" ];
          darwinHosts = [ "cloudbank" ];
        in
          (lib.genAttrs 
            (map (h: "joshsymonds@${h}") linuxHosts)
            (_: mkHome { system = "x86_64-linux"; module = ./home-manager/headless-x86_64-linux.nix; })
          ) // (lib.genAttrs 
            (map (h: "joshsymonds@${h}") darwinHosts)
            (_: mkHome { system = "aarch64-darwin"; module = ./home-manager/aarch64-darwin.nix; })
          );
    };
}
