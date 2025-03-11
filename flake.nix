{
  description = "Josh Symonds' nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    kitty-40.url = "github:leiserfg/nixpkgs/kitty-0.40.0";

    # Darwin
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Secrets
    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Neovim Nightly
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { nixpkgs, nixpkgs-unstable, darwin, home-manager, kitty-40, self, ... }@inputs:
    let
      inherit (self) outputs;

      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems f;

      # Modified kitty package with tests disabled
      modifiedKittyPkgs = system: 
        let
          originalPkgs = kitty-40.legacyPackages.${system};
        in
          originalPkgs.extend (final: prev: {
            kitty = prev.kitty.overrideAttrs (oldAttrs: {
              doCheck = false;
            });
          });

      # Common special arguments for all configurations
      mkSpecialArgs = system: {
        inherit inputs outputs;
        nixpkgs = nixpkgs-unstable;
        kitty-pkgs = modifiedKittyPkgs system;
      };

      # NixOS configuration
      nixosConfiguration = system: hostName: modules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = mkSpecialArgs system;
        modules = modules ++ [{
          home-manager.extraSpecialArgs = mkSpecialArgs system;
        }];
      };

      # Darwin configuration
      darwinConfiguration = system: hostName: modules: darwin.lib.darwinSystem {
        inherit system;
        specialArgs = mkSpecialArgs system;
        modules = modules ++ [{
          home-manager.extraSpecialArgs = mkSpecialArgs system;
        }];
      };

      # Home Manager standalone configuration
      homeConfiguration = system: modules: home-manager.lib.homeManagerConfiguration {
        inherit system;
        pkgs = nixpkgs-unstable.legacyPackages.${system};
        extraSpecialArgs = mkSpecialArgs system;
        modules = modules;
      };
    in
    {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );

      overlays = import ./overlays { inherit inputs; };

      nixosConfigurations = {
        morningstar = nixosConfiguration "x86_64-linux" "morningstar" [ ./hosts/morningstar ];
        ultraviolet = nixosConfiguration "x86_64-linux" "ultraviolet" [ ./hosts/ultraviolet ];
        bluedesert = nixosConfiguration "x86_64-linux" "bluedesert" [ ./hosts/bluedesert ];
        echelon = nixosConfiguration "x86_64-linux" "bluedesert" [ ./hosts/echelon ];
      };

      darwinConfigurations = {
        cloudbank = darwinConfiguration "aarch64-darwin" "cloudbank" [ ./hosts/cloudbank ];
      };

      homeConfigurations = {
        "joshsymonds@morningstar" = homeConfiguration "x86_64-linux" [ ./home-manager ];
        "joshsymonds@ultraviolet" = homeConfiguration "x86_64-linux" [ ./home-manager ];
        "joshsymonds@bluedesert" = homeConfiguration "x86_64-linux" [ ./home-manager ];
        "joshsymonds@echelon" = homeConfiguration "x86_64-linux" [ ./home-manager ];
        "joshsymonds@cloudbank" = homeConfiguration "aarch64-darwin" [ ./home-manager ];
      };
    };
}
