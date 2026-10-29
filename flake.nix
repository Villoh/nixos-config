{
  description = "Multi-user NixOS + DMS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Microsoft fonts extracted from the official Windows 11 ISO; their EULA only covers use on
    # Windows. Private mirror of kugland/nix-ttf-ms-win11-auto, hence git+ssh.
    # No nixpkgs.follows: upstream warns the extraction VM breaks on stable httpdirfs.
    nix-ttf-ms-win11-auto.url = "git+ssh://git@github.com/Villoh/nix-ttf-ms-win11-auto";

    acid-boot = {
      url = "github:kurisu-agent/nix-acid-boot";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Upstream HM module matching the current NixOS DMS release.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/v1.6.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankcalendar = {
      url = "github:AvengeMedia/dankcalendar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fork of satoshoe-dev/dms-profiles (wallpaper picker, per-profile wallpaper folder;
    # upstream PR #2). Back to the plugin registry once it is merged.
    dms-profiles = {
      url = "github:Villoh/dms-profiles/integration";
      flake = false;
    };

    # CLI that turns Omarchy themes into dmsProfiles looks.
    omarchy-dms = {
      url = "github:Villoh/omarchy-dms";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Own CLI tools, packaged by a flake in their repositories.
    holded-tt = {
      url = "github:Villoh/holded-tt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    goopdl = {
      url = "github:Villoh/goopdl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    masamune = {
      url = "github:Villoh/masamune";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.goopdl.follows = "goopdl";
    };

    # Omarchy themes: colors.toml palettes and wallpapers, consumed by dmsProfiles.
    omarchy = {
      url = "github:basecamp/omarchy";
      flake = false;
    };

    base46 = {
      url = "github:AvengeMedia/base46";
      flake = false;
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-browser = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ytm-player = {
      url = "github:peternaame-boop/ytm-player";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xp-music = {
      # Fork branch with the pending PRs (#8 skins, #9 Discord); back to github:Iznardo/xp-music once merged.
      url = "github:Villoh/xp-music?ref=integration";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zapfast = {
      url = "github:crmne/zapfast";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    himalaya-tui = {
      url = "github:pimalaya/himalaya-tui";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";

    # Only used for claude-desktop (official .deb repackaged, daily-updated).
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    arca = {
      url = "github:beyondhumane/arca";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Community packaging of Shiro836/waydroid-nvidia (GPU-accelerated Waydroid).
    waydroid-nvidia-nix = {
      url = "github:yigexuanmu/waydroid-nvidia-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/desktop ];
      };

      checks.${system} = import ./tests {
        inherit inputs system;
        desktop = inputs.self.nixosConfigurations.desktop;
      };

      devShells.${system} = {
        android = import ./shells/android.nix {
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };
        };

        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            git
            gh
            nodejs_24
            nixfmt
            nil
            statix
          ];

          shellHook = ''
            echo "nixos-config development shell"
            echo "Run 'nix flake check' before committing Nix changes."
          '';
        };
      };
    };
}
