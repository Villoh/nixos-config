# Laptop installation (`zenbook`)

Install this repository on the Zenbook as machine-level host `zenbook`. Generate hardware data on that laptop; never copy `hosts/desktop/hardware-configuration.nix`.

## Generate unique hardware configuration

Generate this file on the Zenbook. Never copy `hosts/desktop/hardware-configuration.nix`.

If NixOS is already installed and booted:

```bash
cp /etc/nixos/hardware-configuration.nix \
  hosts/zenbook/hardware-configuration.nix
test -s hosts/zenbook/hardware-configuration.nix
```

If using the NixOS installer before the first configuration:

```bash
sudo nixos-generate-config --root /mnt
sudo install -D -m 0644 \
  /mnt/etc/nixos/hardware-configuration.nix \
  hosts/zenbook/hardware-configuration.nix
test -s hosts/zenbook/hardware-configuration.nix
```

The generated file contains this laptop's filesystems, boot devices, kernel modules, and UUIDs. Review encrypted-root and swap settings for the actual machine. The Zenbook profile enables zswap, which requires persistent swap declared by this generated hardware file. If hibernation is required, configure real persistent encrypted swap and matching resume settings; zswap alone cannot provide hibernation storage.

Do not add `nixosConfigurations.zenbook` to `flake.nix` until `hosts/zenbook/hardware-configuration.nix` exists and belongs to this Zenbook.

## Add host and validate

After the hardware file exists, add a `zenbook` output beside `desktop` in `flake.nix`, using the existing `hosts/zenbook` module:

```nix
nixosConfigurations.zenbook = nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [ ./hosts/zenbook ];
};
```

Then validate and test the machine-level target:

```bash
nix flake check
sudo nixos-rebuild test --flake .#zenbook
```

`test` is temporary and does not change the boot default. Confirm networking, audio, Bluetooth, Hyprland, DankGreeter, DMS, keyboard layout, locking, notifications, and Wayland portals before applying the generation.

## Switch only after testing

Review the diff, especially the generated hardware file, before switching:

```bash
git diff --stat
git diff
sudo nixos-rebuild switch --flake .#zenbook
```

Do not copy desktop hardware or run `switch` before `nix flake check` and the temporary test succeed. The Zenbook profile uses a Spanish keyboard by default; `Alt+Shift` switches to US International for an external US keyboard.
