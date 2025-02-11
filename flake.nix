{
  description = "Josh Symonds' nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

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

    # Neovim
    nixneovim.url = "github:Veraticus/NixNeovim?ref=87241fe110100eb992973d61632f0273c63eaa9a";
  };

  outputs = { nixpkgs, nixpkgs-unstable, darwin, home-manager, self, ... }@inputs:
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

      # Common configurations for NixOS and Darwin
      commonConfig = system: specialArgs: modules: {
        inherit system specialArgs;
        modules = modules;
      };

      nixosConfiguration = system: hostName: modules: nixpkgs.lib.nixosSystem (
        commonConfig system {
          inherit inputs outputs;
          nixpkgs = nixpkgs-unstable;
        } modules
      );

      darwinConfiguration = system: hostName: modules: darwin.lib.darwinSystem (
        commonConfig system {
          inherit inputs outputs;
          nixpkgs = nixpkgs-unstable;
        } modules
      );

      homeConfiguration = system: modules: home-manager.lib.homeManagerConfiguration {
        inherit system;
        pkgs = nixpkgs-unstable.legacyPackages.${system};
        extraSpecialArgs = {
          inherit inputs outputs;
          nixpkgs = nixpkgs-unstable;
        };
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
