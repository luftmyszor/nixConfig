# NixOS Flake Configuration Guidelines

This repository manages the NixOS system and Home Manager configuration for host `luftpad` (user `luftmyszor`).

## Architecture & Module System

- **Flake Entrypoint**: `flake.nix` defines the NixOS configuration and development shells.
- **Dynamic Module Loader**: `lib/loadModules.nix` automatically discovers and imports modules from `modules/`:
  - `*/options.nix`: Module option declarations (loaded by both NixOS and Home Manager).
  - `*/home.nix`: Home Manager configurations for the user.
  - `*/system.nix`: NixOS system-level configurations.
- **Feature Switchboard**: `hosts/default/settings.nix` contains the toggle flags (`modules.<category>.<name>.enable = true;`). To enable or disable a module, edit this file.
- **Host Configuration**: `hosts/default/configuration.nix` (system-level) and `hosts/default/home.nix` (user-level).
- **Theming System**: Colors are centralized in `modules/themes/palette.nix`. Symlinks and palette generation are managed via `theme-switch` (`bin/theme-switch`).

## Rules & Best Practices

1. **Git Staging is Required for Nix Flakes**:
   - Nix Flakes strictly ignore untracked files.
   - **Always stage any newly created file** (`git add <file>`) before running `nix` commands, testing, or rebuilding.
2. **Rebuild Commands**:
   - Switch: `nixSwitch` (alias for `sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)`) or `sudo nixos-rebuild switch --flake .#luftpad`.
   - Test (no boot entry): `nixTest` or `sudo nixos-rebuild test --flake .#luftpad`.
3. **Module Structure**:
   - When introducing new software or services, adhere to the folder convention `modules/<category>/<name>/` (`options.nix`, `home.nix`, and/or `system.nix`).
   - Prefer user-level configuration via `home.nix` unless root/system-level privileges are required.
4. **Formatting**:
   - Format Nix code using standard `nixfmt` (`pkgs.nixfmt`).
   - Maintain consistency with existing file structure and comments.
