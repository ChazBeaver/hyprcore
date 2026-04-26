# hyprcore

The runbook for bringing a new machine from zero to fully configured.

This repo is **not** where logic lives. `appdots` owns apps + configs. `hyprdots`
owns the Hyprland/Linux environment. `hyprcore` is the one-page operator manual
you read when you're staring at a blank install and need to remember what order
to do things in.

## Fresh-machine procedure

### 1. Create the install USB

See `procedures/pre-install/create-usb.md`.

### 2. Install the base OS

Boot from USB, install Omarchy (or Arch+Hyprland, or NixOS). Get to a working
login shell with network access.

### 3. Ensure git and an SSH key

```bash
# If not installed by the base OS
sudo pacman -S --needed git

# Generate and register an SSH key for GitHub
ssh-keygen -t ed25519 -C "you@example.com"
cat ~/.ssh/id_ed25519.pub   # paste into GitHub → Settings → SSH keys
```

### 4. Clone hyprcore and run bootstrap

```bash
mkdir -p ~/Projects/home
cd ~/Projects/home
git clone git@github.com:YOURUSER/hyprcore.git
cd hyprcore
./bootstrap.sh
```

`bootstrap.sh` will:

1. Clone `appdots` and `hyprdots` as siblings under `~/Projects/home/`
2. Run `appdots/bootstrap.sh` (packages → system tweaks → symlinks)
3. Run `hyprdots/bootstrap.sh` (Hyprland env → symlinks)

### 5. Log out and back in

Required for default-shell change (zsh) and Hyprland session selection.

## Updates after initial bootstrap

**Never run `hyprcore/bootstrap.sh` again.** Updates happen per-repo:

```bash
cd ~/Projects/home/appdots  && git pull && ./sync.sh
cd ~/Projects/home/hyprdots && git pull && ./sync.sh
```

Or use the `appdots` / `hyprdots` aliases installed into your shell.

## Drift checking

```bash
drift-check          # appdots diagnostics (via bin/drift-check shim)
~/Projects/home/hyprdots/doctor.sh   # hyprdots diagnostics
```

## Repo boundaries

| Concern                            | Repo     |
|------------------------------------|----------|
| Cross-platform apps + configs      | appdots  |
| App-level install mechanics        | appdots  |
| OS settings (zsh default, macOS defaults) | appdots  |
| Hyprland WM config                 | hyprdots |
| Linux env packages (ddcutil, GTK themes) | hyprdots |
| Distro-specific overrides          | hyprdots (active/omarchy, active/nixos) |
| New-machine procedure              | hyprcore |
| Pre-install docs                   | hyprcore |
