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

    # Dux Shell's HM module (plugin files only). The shell itself is nixpkgs' dux-shell,
    # so this input stays at nixpkgs' version: nixup moves it when nixpkgs moves.
    # nixup: follows nixpkgs#dux-shell
    dms = {
      url = "github:duxlabs-dev/dux-shell/v2.1.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:duxlabs-dev/dux-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fork of satoshoe-dev/dms-profiles (wallpaper picker, per-profile wallpaper folder;
    # upstream PR #2). Back to the plugin registry once it is merged.
    dms-profiles = {
      url = "github:Villoh/dms-profiles/integration";
      flake = false;
    };

    # Alternative shell to DMS, see modules/nixos/desktop/noctalia.nix. The `cachix` branch is the
    # latest commit CI has built. No nixpkgs.follows: overriding it changes the derivation hash
    # and misses the binary cache, so Noctalia would compile locally.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    # Plugin repos, pinned by flake.lock instead of Noctalia's runtime git clones. Plugins are
    # trusted Luau code: review the diff before `nix flake update noctalia-*-plugins`.
    noctalia-official-plugins = {
      url = "github:noctalia-dev/official-plugins";
      flake = false;
    };
    noctalia-community-plugins = {
      url = "github:noctalia-dev/community-plugins";
      flake = false;
    };

    # CLI that turns Omarchy themes into dmsProfiles looks.
    omarchy-dms = {
      url = "github:Villoh/omarchy-dms/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Own CLI tools, packaged by a flake in their repositories.
    holded-tt = {
      url = "github:Villoh/holded-tt/v1.8.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    goopdl = {
      url = "github:Villoh/goopdl/v2.0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    masamune = {
      url = "github:Villoh/masamune/v1.1.2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.goopdl.follows = "goopdl";
    };

    # Omarchy themes: colors.toml palettes and wallpapers, consumed by dmsProfiles.
    omarchy = {
      url = "github:basecamp/omarchy/v4.5.0";
      flake = false;
    };

    base46 = {
      url = "github:duxlabs-dev/base46";
      flake = false;
    };

    # Home Manager module (programs.zen-browser) plus the wrapped package; see modules/home/desktop/zen.nix.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    helium-browser = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ytm-player = {
      url = "github:peternaame-boop/ytm-player/v2.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Music players under evaluation; both ship their own flake.
    sonora = {
      url = "github:sonorahq/sonora/v0.48.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # PENDING: cache. Off while the modules use kopuz-bin (packages/prebuilt): uncomment it
    # together with the source-built line next to that package.
    # kopuz = {
    #   url = "github:Kopuz-org/kopuz";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Local voice dictation. Must follow our nixpkgs: its own pinned glibc can be older than the
    # graphics drivers need, and the window then finds no Vulkan adapter.
    # PENDING: cache. Off while the modules use hex-bin (packages/prebuilt): uncomment it
    # together with the source-built line next to that package.
    # hex = {
    #   url = "github:anomalyco/hex";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Host build (modules/home/communication/packages.nix): 764 derivations compile locally until
    # a cache serves them. Needs a rev with #906 (host app ID for global shortcuts). It follows our
    # nixpkgs so it shares the system's glibc and Mesa (wgpu needs a matching Vulkan stack, as with
    # hex). Cost: every nixpkgs bump rebuilds it, so the pipeline must rebuild it too. The cache
    # hits when the pipeline builds `inputs.serein.packages.<system>.serein` from this same lock.
    # Dropping the follows avoids those rebuilds but risks the glibc/Vulkan mismatch.
    # PENDING: cache. Off while the modules use serein-bin (packages/prebuilt): uncomment it
    # together with the source-built line next to that package.
    # serein = {
    #   url = "github:ViceVerse-cz/Serein";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Follows our nixpkgs although upstream tests against 25.11: it builds and starts on ours
    # (glibc 2.44). Its build hardcodes llvmPackages_21; if a nixpkgs bump drops it, go back to
    # `yapfast.url = "github:yapfast/yapfast";` without follows.
    # PENDING: cache. Off while the modules use yapfast-bin (packages/prebuilt): uncomment it
    # together with the source-built line next to that package.
    # yapfast = {
    #   url = "github:yapfast/yapfast";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Builds from source with the toolchain its rust-toolchain.toml pins, so it keeps its own
    # nixpkgs: a nixpkgs bump here does not recompile it, only a new Sheprd commit does.
    # PENDING: cache. Off while the modules use sheprd-bin (packages/prebuilt): uncomment it
    # together with the source-built line next to that package.
    # sheprd.url = "github:sheprd-labs/sheprd";

    # Keeps its own nixpkgs (nixos-25.11): with unstable's cargoSetupHook its -sys crates
    # (onig, libgit2) need system libraries the derivation does not list.
    himalaya-tui.url = "github:pimalaya/himalaya-tui";

    # Upstream flake (added after v1.1.1, so tracked on main until a release has it).
    strata = {
      url = "github:lgse/strata/v1.2.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Update checker for this repo (nixup check / update); activates only with --test, --switch or --boot.
    nixup = {
      url = "github:Villoh/nixup/v0.11.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # No nixpkgs.follows: upstream tests against its own nixpkgs, and its flake declares a Cachix
    # cache (codex-desktop-linux.cachix.org) that only hits with that exact nixpkgs. Not trusted
    # here: on 2026-11-09 it returned 404 for the path its CI says it pushed, so it builds locally.
    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";

    # Only used for claude-desktop (official .deb repackaged, daily-updated).
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # PENDING: cache. Off while the modules use arca-bin (packages/prebuilt): uncomment it
    # together with the source-built line next to that package.
    # arca = {
    #   url = "github:beyondhumane/arca";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Community packaging of Shiro836/waydroid-nvidia (GPU-accelerated Waydroid).
    waydroid-nvidia-nix = {
      url = "github:yigexuanmu/waydroid-nvidia-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Git worktrees plus agent status in tmux; not in nixpkgs, upstream ships a flake.
    # PENDING: cache. Off while the modules use workmux-bin (packages/prebuilt): uncomment it
    # together with the source-built line next to that package.
    # workmux = {
    #   url = "github:raine/workmux";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      # Own packages (packages/): overlay for the hosts, plain outputs for nix-update/CI.
      overlays.default = _final: prev: import ./packages prev;
      packages.${system} = import ./packages nixpkgs.legacyPackages.${system};

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
