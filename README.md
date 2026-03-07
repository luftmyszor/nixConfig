# nixConfig

A modular NixOS configuration flake for the `luftmyszor` host. The setup uses **Home Manager** for user-level configuration and a custom module-loading library so that each feature (shell, terminal, window manager, …) lives in its own self-contained directory.

---

## Table of Contents

- [Repository Structure](#repository-structure)
- [Flake Inputs & Outputs](#flake-inputs--outputs)
- [Module System](#module-system)
  - [File Conventions](#file-conventions)
  - [Module Loading (lib/loadModules.nix)](#module-loading-libloadmodulesnix)
  - [Enabling / Disabling Modules](#enabling--disabling-modules)
- [Available Modules](#available-modules)
- [Theme System](#theme-system)
  - [Active Palette](#active-palette)
  - [Palette Catalogue](#palette-catalogue)
  - [Using Palette Colors](#using-palette-colors)
- [Dev Shells](#dev-shells)
- [Host Configuration](#host-configuration)
- [Adding a New Module](#adding-a-new-module)
- [Applying the Configuration](#applying-the-configuration)

---

## Repository Structure

```
nixConfig/
├── flake.nix                  # Flake entry point – system configs & dev shells
├── flake.lock                 # Pinned input versions
│
├── bin/
│   └── theme-switch           # Live theme switcher script (also installed via HM)
│
├── hosts/
│   └── default/
│       ├── configuration.nix  # System-level NixOS options & module toggles
│       ├── home.nix           # Home Manager options & module toggles
│       ├── enabledModules.nix # (reserved for future host-specific overrides)
│       ├── hardware-configuration.nix
│       └── systemNixFiles/
│           └── filesystem.nix # Bind-mount /etc/nixos → ~/nixos-flake
│
├── modules/                   # All feature modules (auto-discovered)
│   ├── editors/
│   │   └── vscode/            # VS Code editor
│   ├── services/
│   │   ├── quickshell/        # Quickshell status bar
│   │   ├── swww/              # Animated wallpaper daemon
│   │   ├── waybar/            # Waybar status bar (disabled by default)
│   │   └── wofi/              # Application launcher
│   ├── shells/
│   │   └── zsh/               # Zsh with Oh-My-Zsh
│   ├── terminals/
│   │   └── ghostty/           # Ghostty terminal emulator
│   ├── themes/
│   │   ├── palette.nix        # Build-time color palette (edit to change build theme)
│   │   ├── palette-switcher/  # Runtime palette switcher module (no rebuild needed)
│   │   └── palleteCatalogue/  # Ready-made palette presets
│   └── window-managers/
│       └── hyprland/          # Hyprland Wayland compositor
│           └── configuration/ # Bindings, exec, workspaces, dropdown term
│
├── lib/
│   └── loadModules.nix        # Auto-discovers & imports home/system/options files
│
├── dev-shells/                # Per-language Nix development shells
│   ├── nix.nix
│   ├── python.nix
│   ├── cpp.nix
│   ├── nodejs.nix
│   ├── shell-hook.nix         # Shared shell hook (prompt, package listing)
│   └── scripts/
│       └── nix/
│           └── gen-module     # Script to scaffold a new module from templates
│
└── templates/                 # Module file templates used by gen-module
    ├── home-template.nix
    ├── options-template.nix
    └── system-template.nix
```

---

## Flake Inputs & Outputs

| Input | Purpose |
|---|---|
| `nixpkgs` (nixos-unstable) | Package set and NixOS module library |
| `home-manager` | User-level configuration management |

### Outputs

| Output | Description |
|---|---|
| `nixosConfigurations.luftmyszor` | Full system config for the `luftmyszor` host |
| `devShells.x86_64-linux.nix` | Nix tooling shell (`nixpkgs-fmt`, `statix`, `nil`, …) |
| `devShells.x86_64-linux.python` | Python 3.12 shell (`pip`, `numpy`, `requests`, `pillow`) |
| `devShells.x86_64-linux.cpp` | C/C++ shell (`gcc`, `clang`, `cmake`, `gdb`, …) |
| `devShells.x86_64-linux.nodejs` / `node` / `js` | Node.js shell (`nodejs_24`, `yarn`, `pnpm`) |

---

## Module System

### File Conventions

Each module lives in `modules/<category>/<name>/` and may contain up to three files:

| File | Evaluated by | Purpose |
|---|---|---|
| `options.nix` | Both system & home | Declares `options.modules.<category>.<name>.enable` (and any extra options) |
| `system.nix` | NixOS (`configuration.nix`) | System-level configuration (packages, services, kernel options, …) |
| `home.nix` | Home Manager (`home.nix`) | User-level configuration (dotfiles, user packages, program settings, …) |

### Module Loading (`lib/loadModules.nix`)

`lib/loadModules.nix` recursively walks `modules/` and collects every file whose name matches a known suffix:

```nix
loadHomeModules   # imports every home.nix found under modules/
loadSystemModules # imports every system.nix found under modules/
loadOptions       # imports every options.nix found under modules/
```

Both `hosts/default/configuration.nix` and `hosts/default/home.nix` call this library so that **every** module is always present in the Nix evaluation — modules are activated or deactivated purely via their `enable` option.

### Enabling / Disabling Modules

Toggle a module by setting its `enable` option in **both** files (they share the same option namespace):

**`hosts/default/configuration.nix`** (system context)
```nix
modules.shells.zsh.enable              = true;
modules.terminals.ghostty.enable       = true;
modules.window-managers.hyprland.enable = true;
modules.services.quickshell.enable     = true;
modules.services.waybar.enable         = false; # disabled
modules.services.swww.enable           = true;
modules.services.wofi.enable           = true;
modules.editors.vscode.enable          = true;
```

**`hosts/default/home.nix`** (home-manager context) — mirrors the same flags.

---

## Available Modules

### Shells — `modules/shells`

| Module | Option | Description |
|---|---|---|
| zsh | `modules.shells.zsh.enable` | Zsh with Oh-My-Zsh (`agnoster` theme, `git` plugin, autosuggestions, syntax highlighting) |

### Terminals — `modules/terminals`

| Module | Option | Description |
|---|---|---|
| ghostty | `modules.terminals.ghostty.enable` | Ghostty terminal emulator — runtime colors managed by `palette-switch` |

### Window Managers — `modules/window-managers`

| Module | Option | Description |
|---|---|---|
| hyprland | `modules.window-managers.hyprland.enable` | Hyprland Wayland compositor with keybindings, workspaces, and a dropdown terminal |

**Hyprland sub-configuration** (all under `modules/window-managers/hyprland/configuration/`):

| File | What it configures |
|---|---|
| `bindings.nix` | Keyboard & mouse bindings (`$mod = SUPER`); workspace switching; wofi launcher; volume & brightness media keys |
| `exec.nix` | `exec` entries run at startup |
| `workspace.nix` | Default workspace gaps and layout rules |
| `dropdownTerm.nix` | `special:dropdown` scratchpad workspace bound to `` $mod+` `` |

### Services — `modules/services`

| Module | Option | Description |
|---|---|---|
| quickshell | `modules.services.quickshell.enable` | Quickshell-based status bar; config files are copied from `configuration/shell.qml` |
| swww | `modules.services.swww.enable` | Animated wallpaper daemon (`swww-daemon`) managed as a systemd user service |
| waybar | `modules.services.waybar.enable` | Waybar status bar with a drop-down animation script (`dropWaybar.sh`); **disabled by default** |
| wofi | `modules.services.wofi.enable` | Wofi application launcher; config and CSS are generated from the active palette |

### Themes — `modules/themes`

| Module | Option | Description |
|---|---|---|
| palette-switcher | `modules.themes.palette-switcher.enable` | Runtime palette switcher — deploys palette JSON files, installs `palette-switch` script, and generates module configs on activation |

### Editors — `modules/editors`

| Module | Option | Description |
|---|---|---|
| vscode | `modules.editors.vscode.enable` | VS Code (FHS build) with Nix, C++, and C# extensions; `nil` LSP included |

---

## Theme System

### Active Palette

`modules/themes/palette.nix` is the **static palette** used at Nix-build time (for modules that still reference it, such as `wofi`). It is imported in `flake.nix` and passed as a special argument (`palette`) to every module that needs it at build time.

The current build-time theme is **Tokyo Night**. To change the build-time theme you still replace the contents of `palette.nix` with any file from `palleteCatalogue/` and rebuild.

---

### Live Theme Switcher (`theme-switch`)

`theme-switch` is a high-performance runtime switcher that reads directly from the
palette catalogue (`.nix` files) instead of the pre-deployed JSON snapshots used
by `palette-switch`.  No NixOS/Home Manager rebuild is needed after switching.

#### How it works

1. After `home-manager switch` two stable symlinks exist:
   - `~/.config/theme/palette.json` → `~/.cache/theme/current/palette.json`
   - `~/.config/theme/palette.css`  → `~/.cache/theme/current/palette.css`
2. On first activation the cache files are seeded from the build-time palette
   (`~/nixTheme/palette.{json,css}`).
3. Running `theme-switch <name>` atomically updates both cache files in-place,
   so anything reading `~/.config/theme/` sees the new theme immediately.

#### Usage

```bash
# List available themes (reads from the palette catalogue)
theme-switch list

# Switch to a theme and reload running apps
theme-switch nord
theme-switch gruvbox
theme-switch tokyo-night
theme-switch everforest

# Override the catalogue directory (useful for testing a custom palette)
THEME_CATALOGUE_DIR=~/my-palettes theme-switch my-theme
```

#### What it updates

| File | Description |
|---|---|
| `~/.cache/theme/current/palette.json` | JSON object with all palette keys |
| `~/.cache/theme/current/palette.css`  | CSS custom-properties (`:root { --key: value; }`) |
| `~/.cache/theme/current.theme`        | Plain-text file recording the active theme name |

#### Reload hooks (best-effort)

| Program | Signal / command |
|---|---|
| **waybar** | `pkill -USR2 waybar` |
| **hyprland** | `hyprctl reload` |
| **sway** | `swaymsg reload` |

Missing programs are silently skipped — `theme-switch` never exits non-zero due
to a program not running.

---

### Runtime Palette Switching (no rebuild needed)

The `palette-switcher` module (`modules/themes/palette-switcher/`) provides **runtime palette switching** using a `palette-switch` script. After one initial NixOS build, you can swap themes instantly without triggering a rebuild.

#### How it works

1. **After the first build**, five palette JSON files are deployed to `~/.config/palettes/`:
   - `tokyo-night.json`, `gruvbox.json`, `nord.json`, `everforest.json`, `catppuccin.json`
2. `~/.config/palettes/active.json` is a symlink pointing to the current palette.
3. `palette-switch` reads `active.json` with `jq`, renders config files for every supported module, and reloads running programs.

#### Usage

```bash
# List available palettes (active one is marked with *)
palette-switch list

# Switch to a palette and apply immediately
palette-switch tokyo-night
palette-switch gruvbox
palette-switch nord
palette-switch everforest
palette-switch catppuccin

# Re-render all configs from the current active palette (e.g. after a fresh install)
palette-switch apply
```

#### Supported modules

| Module | Config generated | Reload hook |
|---|---|---|
| **Ghostty** | `~/.config/ghostty/colors.conf` | New windows pick up colors automatically |
| **Waybar** | `~/.config/waybar/normal-style.css` | `pkill -SIGUSR2 waybar` |
| **Hyprland** | `~/.config/hypr/palette-colors.conf` | `hyprctl reload` |
| **Neovim** | `~/.config/nvim/lua/palette-colors.lua` | Running instances signaled via socket |

##### Neovim integration

Add the following line to your `~/.config/nvim/init.lua` to apply the palette automatically when Neovim starts:

```lua
pcall(function() require('palette-colors').apply() end)
```

---

### Palette Catalogue

All palette files expose the same set of color keys:

| Key | Role |
|---|---|
| `bg` | Main window / background |
| `programBg` | Application / widget background |
| `fg` | Default foreground / text |
| `primary` | Primary accent (blue in Tokyo Night) |
| `secondary` | Secondary accent (purple) |
| `tertiary` | Tertiary accent (teal) |
| `accent` | Alias for `primary` |
| `danger` | Error / destructive actions (red) |
| `warning` | Warnings (yellow) |
| `success` | Success / positive state (green) |
| `info` | Informational (cyan) |
| `black` / `dark` / `muted` / `light` / `white` | Greyscale ramp |
| `bgTransparent` / `darkTransparent` | Semi-transparent variants for overlays |

### Palette Catalogue

Ready-made themes live in `modules/themes/palleteCatalogue/`:

| File | Theme |
|---|---|
| `tokyo-night.nix` | Tokyo Night (current default in `palette.nix`) |
| `everforest.nix` | Everforest — warm green forest palette |
| `nord.nix` | Nord — arctic, north-bluish palette |
| `gruvebox.nix` | Gruvebox variant |
| `palette.nix` | Catppuccin Mocha-inspired palette |

### Using Palette Colors

The palette is available as the `palette` argument in any `home.nix` or `system.nix` that declares it:

```nix
{ config, pkgs, lib, palette, ... }:
{
  # Example usage
  some.option.color = palette.primary;
}
```

Two pre-generated theme files are written to the user's home directory at build time:
- `~/nixTheme/palette.json` — JSON object of all palette keys (for script use)
- `~/nixTheme/palette.css` — CSS custom properties (`:root { --primary: …; }`) with base `window` and `#input` rules

---

## Dev Shells

Enter a shell with `nix develop .#<name>` from the repo root:

| Shell name | Aliases | Key tools |
|---|---|---|
| `nix` | — | `nixpkgs-fmt`, `statix`, `deadnix`, `nil`, `nvd`, `nix-diff`, `nix-tree`, `nix-output-monitor` |
| `python` | — | Python 3.12 with `pip`, `numpy`, `requests`, `pillow` |
| `cpp` | — | `gcc`, `clang`, `cmake`, `ninja`, `gdb`, `lldb`, `valgrind`, `cppcheck` |
| `nodejs` | `node`, `js` | `nodejs_24`, `yarn`, `pnpm` |

Every shell uses the shared `shell-hook.nix` which:
- Sets a colored prompt showing the shell name and current directory
- Prints a welcome message with the current user and shell
- Exposes a `shell-pkgs` function that lists all packages in the shell

The `nix` shell additionally defines two aliases:
```bash
nixSwitch  # sudo nixos-rebuild switch --flake /etc/nixos#luftmyszor
nixTest    # sudo nixos-rebuild test   --flake /etc/nixos#luftmyszor
```

Shell-specific scripts can be placed in `dev-shells/scripts/<shell-name>/` and are automatically added to `PATH` when the shell is entered.

---

## Host Configuration

The `luftmyszor` host (in `hosts/default/`) represents a single x86_64-linux machine with:

- **Bootloader**: systemd-boot (EFI)
- **Kernel**: latest (`linuxPackages_latest`)
- **Hostname**: `nixmyszor`
- **Network**: NetworkManager
- **Locale**: `en_US.UTF-8` with `pl_PL.UTF-8` regional formats, keyboard layout `pl`
- **Timezone**: `Europe/Warsaw`
- **Audio**: PipeWire (ALSA + PulseAudio compat, rtkit)
- **Display**: X11 with GDM + GNOME (used as a session chooser; the primary DE is Hyprland)
- **Printing**: CUPS enabled
- **Nix**: experimental features `nix-command`, `flakes`, `pipe-operators`

### System packages (always installed)

`neovim`, `wget`, `tree`, `fastfetch`, `wl-clipboard`, `brightnessctl`, `gimp3-with-plugins`, `inkscape-with-extensions`, `gh`, `git`, `vim`, `jq`, `mupdf`

> `vim` is kept alongside `neovim` as a minimal, always-available fallback (e.g. for `visudo` or recovery situations where neovim's plugins are not needed).

### Filesystem mount

`/etc/nixos` is bind-mounted from `~/nixos-flake` so that `nixos-rebuild` can find the flake at the standard path without needing root ownership of the repo.

---

## Adding a New Module

Use the `gen-module` script (available in the `nix` dev shell):

```bash
nix develop .#nix
gen-module <category>.<name>
# example:
gen-module services.dunst
```

The script:
1. Reads the templates from `templates/`
2. Creates `modules/<category>/<name>/options.nix`, `home.nix`, `system.nix`
3. Substitutes `{{name}}` and `{{path}}` placeholders with the real values

After generation:
1. Enable the module in `hosts/default/configuration.nix` and/or `hosts/default/home.nix`
2. Fill in the generated `home.nix` / `system.nix` with the actual configuration
3. Rebuild with `nixSwitch` (or `nixTest` for a non-persistent test)

---

## Applying the Configuration

```bash
# Switch (persistent — survives reboot)
sudo nixos-rebuild switch --flake /etc/nixos#luftmyszor

# Test (active until next reboot)
sudo nixos-rebuild test --flake /etc/nixos#luftmyszor

# Build only (no activation)
sudo nixos-rebuild build --flake /etc/nixos#luftmyszor
```

Inside the `nix` dev shell the first two are aliased to `nixSwitch` and `nixTest`.
