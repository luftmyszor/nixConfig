# Bootstrapping on a New Machine

This guide explains how to set up this NixOS flake on a freshly-installed machine (or after cloning the repo for the first time).

---

## Table of Contents

- [Why `hardware-configuration.nix` Is Not in the Repo](#why-hardware-configurationnix-is-not-in-the-repo)
- [Step-by-Step Setup](#step-by-step-setup)
- [The `/boot` ESP Mount Problem](#the-boot-esp-mount-problem)
  - [Symptoms](#symptoms)
  - [Root Cause](#root-cause)
  - [Fix](#fix)
- [Troubleshooting](#troubleshooting)

---

## Why `hardware-configuration.nix` Is Not in the Repo

`hosts/default/hardware-configuration.nix` is **gitignored** on purpose. It contains machine-specific details (UUIDs, disk layout, kernel modules) that differ between machines. Committing it would make the flake fail to evaluate on any other hardware.

When neither `hardware-configuration.nix` nor `systemNixFiles/filesystem.nix` is present, the flake falls back to a minimal tmpfs stub so that CI and fresh clones can still evaluate without errors.

---

## Step-by-Step Setup

### 1. Install NixOS normally

Follow the standard NixOS installation (manual or `nixos-install`). This creates `/etc/nixos/hardware-configuration.nix` with values specific to your disk layout.

### 2. Clone this repo

```bash
git clone https://github.com/luftmyszor/nixConfig ~/nixos-flake
cd ~/nixos-flake
```

### 3. Place a machine-specific hardware config

Generate a fresh hardware config or copy the one from `/etc/nixos/`:

```bash
# Option A — copy the installer-generated file
cp /etc/nixos/hardware-configuration.nix hosts/default/hardware-configuration.nix

# Option B — regenerate from the running system
sudo nixos-generate-config --root / --dir /tmp/hwcfg
cp /tmp/hwcfg/hardware-configuration.nix hosts/default/hardware-configuration.nix
```

### 4. Ensure `/boot` is configured as a real VFAT filesystem

Open `hosts/default/hardware-configuration.nix` and make sure the `/boot` entry looks like this:

```nix
fileSystems."/boot" = {
  device = "/dev/disk/by-uuid/YOUR-ESP-UUID";
  fsType = "vfat";
  options = [ "fmask=0077" "dmask=0077" ];
};
```

Find the correct UUID with:

```bash
lsblk -f
# or
blkid | grep -i vfat
```

> **Important:** The device must be the EFI System Partition (ESP), typically the small FAT32 partition at the start of the disk. Using `autofs` or leaving out `fsType = "vfat"` will cause systemd-boot to fail — see [The `/boot` ESP Mount Problem](#the-boot-esp-mount-problem) below.

### 5. Set up the `/etc/nixos` bind-mount (optional but recommended)

The `filesystem.nix` module bind-mounts `~/nixos-flake` to `/etc/nixos` so that `nixos-rebuild` finds the flake at the standard path. On first boot this isn't active yet, so pass the flake path directly:

```bash
sudo nixos-rebuild switch --impure --flake ~/nixos-flake#nixmyszor
```

After the first successful switch the bind-mount is active, and subsequent rebuilds can use the `nixSwitch` alias (from the `nix` dev shell) or:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixmyszor
```

### 6. Mount `/boot` if the rebuild fails at bootloader install

If the rebuild fails with:

```
efiSysMountPoint = '/boot' is not a mounted partition.
```

mount `/boot` manually and retry:

```bash
sudo mount -t vfat /dev/disk/by-uuid/YOUR-ESP-UUID /boot
sudo nixos-rebuild switch --impure --flake ~/nixos-flake#nixmyszor
```

---

## The `/boot` ESP Mount Problem

### Symptoms

- `nixos-rebuild switch` fails with:
  ```
  efiSysMountPoint = '/boot' is not a mounted partition.
  systemd-boot: Command '[check-mountpoints]' returned non-zero exit status 1.
  ```
- `grep /boot /etc/fstab` shows `autofs` instead of `vfat`.
- `boot.mount` unit is missing or fails.

### Root Cause

NixOS generates `/etc/fstab` from the `fileSystems` option. If `hardware-configuration.nix` defines `/boot` with `fsType = "autofs"` (which `nixos-generate-config` sometimes produces for automount stubs) — or if `fsType` is missing entirely — systemd cannot mount `/boot` as the real FAT32 ESP when the bootloader installer runs.

### Fix

#### Quick fix — correct `hardware-configuration.nix`

Set `fsType = "vfat"` in the `/boot` entry as shown in [Step 4](#4-ensure-boot-is-configured-as-a-real-vfat-filesystem).

#### If the system is already stuck in a broken state

1. **Switch without the bootloader step** (`test` mode does not install a bootloader):
   ```bash
   sudo nixos-rebuild test --impure --flake ~/nixos-flake#nixmyszor
   ```
   This regenerates `/etc/fstab` with the correct `vfat` entry without trying to install the bootloader.

2. **Mount `/boot` and install the bootloader manually:**
   ```bash
   sudo mount -t vfat /dev/disk/by-uuid/YOUR-ESP-UUID /boot
   findmnt /boot   # confirm it is mounted
   sudo nixos-rebuild boot --impure --flake ~/nixos-flake#nixmyszor --install-bootloader
   ```

3. **Run a full switch:**
   ```bash
   sudo nixos-rebuild switch --impure --flake ~/nixos-flake#nixmyszor
   ```

#### Verify

```bash
grep /boot /etc/fstab          # should show vfat, not autofs
findmnt /boot                  # should show /dev/nvme... vfat
sudo bootctl status            # should list nixos-generation-*.conf entries
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `error: getting status of '/nix/store/…/hardware-configuration.nix': No such file or directory` | `hardware-configuration.nix` missing | Follow [Step 3](#3-place-a-machine-specific-hardware-config) |
| `/boot` shows `autofs` in `/etc/fstab` | Wrong `fsType` in hardware config | Set `fsType = "vfat"` — see [Step 4](#4-ensure-boot-is-configured-as-a-real-vfat-filesystem) |
| `efiSysMountPoint = '/boot' is not a mounted partition` | `/boot` not mounted at rebuild time | Mount manually and rerun — see [Step 6](#6-mount-boot-if-the-rebuild-fails-at-bootloader-install) |
| Evaluation warnings about renamed options | Stale NixOS option names | Already fixed in this repo; update your local clone if you see them |
| `error: flake attribute 'nixosConfigurations.luftmyszor' not found` | Old flake attribute name | Use `#nixmyszor` (the hostname) — the attribute was renamed to match `networking.hostName` |
