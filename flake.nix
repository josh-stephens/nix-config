{
  description = "Josh Symonds' nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    # Darwin
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-23.05-darwin";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    darwin-nix.url = "github:yorickvP/nix/boost-regex";

    # Secrets
    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Hardware
    hardware.url = "github:nixos/nixos-hardware";
    xremap-flake.url = "github:xremap/nix-flake";

    # UI
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    hyprland.url = "github:hyprwm/Hyprland?ref=f7cdebd84a69432fd80fa3d3f69dd829e3941376";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    xdg-portal-hyprland.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    eww-exclusiver = {
      url = "github:matt1432/eww-exclusiver";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    rust-overlay.url = "github:oxalica/rust-overlay";

    # Neovim
    nixneovim.url = "github:Veraticus/nixneovim";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    nix-colors.url = "github:misterio77/nix-colors";

    # nix-gaming
    nix-gaming.url = "github:fufexan/nix-gaming";
  };

  outputs = { nixpkgs, darwin, home-manager, self, ... }@inputs:
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
        commonConfig system { inherit inputs outputs; } modules
      );

      darwinConfiguration = system: hostName: modules: darwin.lib.darwinSystem (
        commonConfig system { inherit inputs outputs; } modules
      );
      homeConfiguration = system: modules: home-manager.lib.homeManagerConfiguration {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit inputs outputs; };
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
      };

      darwinConfigurations = {
        cloudbank = darwinConfiguration "aarch64-darwin" "cloudbank" [ ./hosts/cloudbank ];
      };

      homeConfigurations = {
        "joshsymonds@morningstar" = homeConfiguration "x86_64-linux" [ ./home-manager ];
        "joshsymonds@ultraviolet" = homeConfiguration "x86_64-linux" [ ./home-manager ];
        "joshsymonds@cloudbank" = homeConfiguration "aarch64-darwin" [ ./home-manager ];
      };
    };
}
