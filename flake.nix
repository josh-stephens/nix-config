{
  description = "Josh Symonds' nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Darwin
    nixpkgsDarwin.url = "github:nixos/nixpkgs/nixpkgs-22.11-darwin";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgsDarwin";

    # Secrets
    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # Hardware
    hardware.url = "github:nixos/nixos-hardware";
    xremap-flake.url = "github:xremap/nix-flake";

    # UI
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    hyprland.url = "github:hyprwm/Hyprland";
    xdg-portal-hyprland.url = "github:hyprwm/xdg-desktop-portal-hyprland";

    # Neovim
    nixneovim.url = "github:Veraticus/nixneovim";

    # Discord
    webcord.url = "github:fufexan/webcord-flake";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { nixpkgs, darwin, home-manager, self, ... }@inputs: {
    nixosConfigurations.morningstar = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; }; # Pass flake inputs to our config
      # > Our main nixos configuration file <
      modules = [ ./nixos/morningstar ];
    };

    darwinConfigurations.cloudbank = darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # "x86_64-darwin" if you're using a pre M1 mac
      specialArgs = { inherit inputs; }; # Pass flake inputs to our config
      modules = [ ./hosts/cloudbank ]; # will be important later
    };
    

    homeConfigurations = {
      "joshsymonds@morningstar" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        # > Our main home-manager configuration file <
        modules = [ ./home-manager ];
      };
      "joshsymonds@cloudbank" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        # > Our main home-manager configuration file <
        modules = [ ./home-manager ];
      };

    };
  };
}
