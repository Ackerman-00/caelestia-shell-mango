<h1 align="center">caelestia-shell <sub>MangoWM Port</sub></h1>

<div align="center">

![License](https://img.shields.io/github/license/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![Quickshell](https://img.shields.io/badge/quickshell-0.3-64DBB5?style=for-the-badge&labelColor=101418)
![wlroots](https://img.shields.io/badge/wlroots-0.20-7B68EE?style=for-the-badge&labelColor=101418)

</div>

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

---

## Install

### Fedora Packages (COPR)

All Fedora builds for caelestia-shell and its dependencies are available in the Nexus COPR repository:

```sh
sudo dnf copr enable ackerman/nexus
sudo dnf install caelestia-shell-mango
```

Also install **[caelestia-cli-mango](https://github.com/Ackerman-00/caelestia-cli-mango)** — the MangoWM fork of the `caelestia` CLI that drives colour schemes and wallpapers (required for `caelestia scheme set`, `caelestia wallpaper`):

```sh
sudo dnf install caelestia-cli-mango
```

### Build Dependencies

| Dependency | Needed for |
|------------|-----------|
| `cmake` (≥ 3.19), `ninja-build` | build system |
| `gcc-c++` or `clang` | C++20 compiler |
| `pkgconf-pkg-config` | dependency detection |
| Qt6 `qtbase-devel` + `qtdeclarative-devel` | Qt6 core, gui, qml, quick, network, dbus, sql, concurrent |
| `qt6-qtwayland-devel` | Wayland integration |
| `qt6-qtshadertools-devel` | shader compilation |
| `libglvnd-devel` | OpenGL loader |
| `wayland-devel` | Wayland protocols |
| `libqalculate-devel` | in-app calculator |
| `pipewire-devel` | audio control |
| `aubio-devel` | audio beat detection |
| `libcava-devel` | audio visualiser |
| `fftw-devel` | FFT (cava dependency) |
| `material-symbols-fonts` | icon set |
| `cascadia-code-nerd-fonts` | monospace font |

Install the **development** packages for each dependency via your distro's package manager.

### Runtime Dependencies

| Package | Notes |
|---------|-------|
| `quickshell-git` | must be git version, not latest tagged |
| `mangowm` | with `mmsg` IPC support |
| `libpipewire` | audio control |
| `networkmanager` | network info |
| `lm-sensors` | hardware monitoring |
| `libcava` | audio visualiser |
| `grim` | active-window preview (`grim -T <foreign_toplevel_id>`) |
| `swappy` | screenshot editor |
| `wl-clipboard` | clipboard access (`wl-copy`, `wl-paste`) |
| `cliphist` | clipboard history (powered by `wl-clipboard`) |
| [`caelestia-cli-mango`](https://github.com/Ackerman-00/caelestia-cli-mango) | colour scheme & wallpaper management (`caelestia scheme set`, `caelestia wallpaper`). MangoWM fork of `caelestia-dots/cli` (no Hyprland coupling); available as the `caelestia-cli-mango` COPR package or via `pip install --user -e <repo>`. Generates colors from wallpapers via `materialyoucolor` (not `matugen`). |
| `libnotify` | desktop notifications (`notify-send`) |
| `procps` | process monitoring (`pidof`) |
| `util-linux` | disk info (`lsblk`) |
| `libxml2` | XKB layout parsing (`xmllint`) |
| `fprintd` | fingerprint authentication |
| `app2unit` | application launcher (converts desktop entries to systemd units) |
| `systemd` | session management (`loginctl`, `systemctl`) |
| `polkit` | privilege escalation (`pkexec`) |
| `iproute2` | VPN/wireguard status (`ip link show`) |
| `bash` | used throughout for shell commands |

> **Note:** Keyboard layout switching uses `setxkbmap` (tool-agnostic). No Hyprland dependencies remain.

### Optional

| Package | Notes |
|---------|-------|
| `libqalculate` | in-app calculator |
| `aubio` | audio beat detection |
| `ddcutil` | external monitor control |
| `gpu-screen-recorder` | screen recording (monitored via `pidof`) |
| `brightnessctl` | backlight control (needed if not using `ddcutil`) |
| `asdbctl` | ASUS external display backlight control (only if ASUS) |
| `nvidia-smi` / `glxinfo` / `lspci` | GPU name detection (fallback chain) |
| `tailscale` / `netbird` / `warp-cli` | VPN provider status in the network pane (only if used) |
| `fish` | calculator integration shell |

### Manual Install (CMake)

Builds the C++ QML plugin and installs everything system-wide.

```sh
git clone https://github.com/Ackerman-00/caelestia-shell-mango
cd caelestia-shell-mango

cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/ \
  -DENABLE_MODULES="extras;plugin;shell" \
  -DINSTALL_LIBDIR=/usr/lib64/caelestia \
  -DINSTALL_QMLDIR=/usr/lib64/qt6/qml \
  -DINSTALL_QSCONFDIR=/usr/share/caelestia-shell

cmake --build build
sudo cmake --install build
```

Then create the `caelestia-shell` wrapper used by IPC calls, keybinds and autostart
(the Fedora package installs the same wrapper automatically):

```sh
sudo tee /usr/bin/caelestia-shell > /dev/null << 'EOF'
#!/bin/bash
export CAELESTIA_LIB_DIR="/usr/lib64/caelestia"
exec /usr/bin/qs -p "/usr/share/caelestia-shell" "$@"
EOF
sudo chmod +x /usr/bin/caelestia-shell
```

Adjust `INSTALL_LIBDIR`/`INSTALL_QMLDIR`/`INSTALL_QSCONFDIR` for your distro
(Fedora uses `/usr/lib64`; Debian/Arch typically `/usr/lib`) and mirror the paths
inside the wrapper script above.

### Nix Build

```sh
git clone https://github.com/Ackerman-00/caelestia-shell-mango
cd caelestia-shell-mango

nix build .#caelestia-shell
```

The built binary is at `result/bin/caelestia-shell`. Run directly:

```sh
./result/bin/caelestia-shell -d
```

#### System-wide install (nix profile)

```sh
nix profile install .#caelestia-shell
```

This installs `caelestia-shell` to `~/.nix-profile/bin/`, placing it in your PATH on NixOS. Verify with `which caelestia-shell`.

> **env.conf:** After nix profile install, ensure `~/.nix-profile/bin` is in MangoWM's PATH (see [env.conf](#envconf) below).

---

## MangoWM Config

> **Need MangoWM's dotfiles/keybinds?** The full compositor configuration (keybinds, rules,
> monitor setup, `mango_core.conf`) lives in [mango-config](https://github.com/Ackerman-00/mango-config.git) — head over there.

### env.conf

> **NixOS only.** MangoWM already has standard system paths in its default PATH.
> Only needed to add nix-specific paths:
> ```
> env=PATH,/home/<username>/.nix-profile/bin:/run/current-system/sw/bin:~/.local/bin:/usr/bin:/bin
> ```

> Caelestia sets `XDG_CURRENT_DESKTOP`, `XDG_SESSION_DESKTOP`, `SDL_VIDEODRIVER`, and `XDG_DESKTOP_PORTAL` at startup — no need to put those in env.conf.

### Autostart

Add to `~/.config/mango/config.conf`:

```
exec-once = caelestia-shell -d
```

### Blur Rule

Add to `~/.config/mango/rule.conf` to disable blur on shell surfaces:

```
noblur:1 caelestia
```

### Keybinds

Add to `~/.config/mango/mango_bind.conf`:

```conf
# ─── CAELESTIA SHELL IPC ───────────────────────────────────
bind=SUPER,a,spawn_shell,caelestia-shell ipc call drawers toggle launcher
bind=SUPER,v,spawn_shell,caelestia-shell ipc call clipboard open
bind=SUPER,comma,spawn_shell,caelestia-shell ipc call controlCenter open
bind=SUPER,w,spawn_shell,caelestia-shell ipc call wallpaper openMenu
bind=CTRL+ALT,w,spawn_shell,caelestia-shell ipc call wallpaper random
bind=SUPER+p,spawn_shell,caelestia-shell ipc call drawers toggle dashboard
bind=SUPER+l,spawn_shell,caelestia-shell ipc call lock lock
bind=SUPER+SHIFT,Print,spawn_shell,caelestia-shell ipc call picker open
bind=CTRL+ALT,U,spawn_shell,caelestia-shell ipc call record start
bind=CTRL+ALT,P,spawn_shell,caelestia-shell ipc call record togglePause
bind=CTRL+ALT,S,spawn_shell,caelestia-shell ipc call record stop
bind=CTRL+ALT,Delete,spawn_shell,caelestia-shell ipc call drawers toggle session
bind=NONE,XF86AudioRaiseVolume,spawn_shell,caelestia-shell ipc call audio set 5%+
bind=NONE,XF86AudioLowerVolume,spawn_shell,caelestia-shell ipc call audio set 5%-
bind=NONE,XF86AudioMute,spawn_shell,caelestia-shell ipc call audio mute
```

> `spawn_shell` routes through `/bin/sh -c`, ensuring shell pipelines and argument handling work correctly. `caelestia-shell` is resolved via `env.conf` PATH.

---

## IPC Reference

All IPC commands go through `caelestia-shell` (in PATH after system-wide install):

```sh
caelestia-shell ipc call <target> <function> [args...]
```

When running the dev shell from the repo (`quickshell -p /path/to/repo`), target the
running instance's shell dir instead:

```sh
quickshell ipc -p /path/to/repo call <target> <function> [args...]
```

### drawers

Toggle launcher, dashboard, sidebar, utilities, session, and OSD panels.

| Function | Signature | Description |
|----------|-----------|-------------|
| `toggle` | `toggle(drawer: string)` | Toggle a drawer (`launcher`, `dashboard`, `utilities`, `sidebar`, `session`, `osd`) |
| `list` | `list(): string` | List available drawer names |
| `isOpen` | `isOpen(drawer: string): string` | Check if a drawer is open (`"1"` / `"0"` / `"unknown"`) |

### clipboard

Open the launcher directly into clipboard history mode.

| Function | Signature | Description |
|----------|-----------|-------------|
| `open` | `open(): void` | Open launcher with clipboard history |

### controlCenter

Open the settings/control center window.

| Function | Signature | Description |
|----------|-----------|-------------|
| `open` | `open(): void` | Open control center |
| `openPane` | `openPane(pane: string): void` | Open control center on a specific pane (`appearance`, `audio`, `bluetooth`, `dashboard`, `launcher`, `network`, `notifications`, `session`, `taskbar`) |

### wallpaper

Manage wallpapers. All functions use the configured `paths.wallpaperDir`
(see [Paths](#paths)) — no hardcoded directory. The folder can also be picked
manually from **Settings → Appearance → Background → Wallpaper folder** (writes the
same `paths.wallpaperDir` config key).

| Function | Signature | Description |
|----------|-----------|-------------|
| `get` | `get(): string` | Get current wallpaper path |
| `set` | `set(path: string): void` | Set wallpaper by path |
| `random` | `random(): void` | Set a random wallpaper from the configured wallpaper directory (runs `caelestia wallpaper -r <wallsdir>`) |
| `list` | `list(): string` | List all available wallpaper paths |
| `openMenu` | `openMenu(): void` | Open launcher with wallpaper picker |

### notifs

Notification controls.

| Function | Signature | Description |
|----------|-----------|-------------|
| `clear` | `clear(): void` | Clear all notifications |
| `toggleDnd` | `toggleDnd(): void` | Toggle Do Not Disturb |
| `enableDnd` | `enableDnd(): void` | Enable Do Not Disturb |
| `disableDnd` | `disableDnd(): void` | Disable Do Not Disturb |
| `isDndEnabled` | `isDndEnabled(): bool` | Check DND status |

### mpris

Media player control.

| Function | Signature | Description |
|----------|-----------|-------------|
| `play` | `play(): void` | Play |
| `pause` | `pause(): void` | Pause |
| `playPause` | `playPause(): void` | Toggle play/pause |
| `next` | `next(): void` | Next track |
| `previous` | `previous(): void` | Previous track |
| `stop` | `stop(): void` | Stop |
| `list` | `list(): string` | List available players |
| `getActive` | `getActive(prop: string): string` | Get property from active player (`"trackTitle"`, `"identity"`, etc.) |

### audio

Audio device control.

| Function | Signature | Description |
|----------|-----------|-------------|
| `get` | `get(): real` | Get current volume (0–1) |
| `set` | `set(value: string): string` | Set volume (`0.5`, `+0.05`, `5%+`, `5%-`, `+10%`, `10%-`) |
| `mute` | `mute(): void` | Toggle mute |
| `cycleOutput` | `cycleOutput(): void` | Cycle to next audio output sink |

### brightness

Monitor brightness control.

| Function | Signature | Description |
|----------|-----------|-------------|
| `get` | `get(): real` | Get active monitor brightness |
| `getFor` | `getFor(query: string): real` | Get brightness for specific monitor |
| `set` | `set(value: string): string` | Set brightness (`0.5`, `+10%`, `10%-`) |
| `setFor` | `setFor(query: string, value: string): string` | Set brightness for specific monitor |

### lock

Session lock.

| Function | Signature | Description |
|----------|-----------|-------------|
| `lock` | `lock(): void` | Lock session |
| `unlock` | `unlock(): void` | Unlock session |
| `isLocked` | `isLocked(): bool` | Check if locked |

### picker

Area screenshot picker.

| Function | Signature | Description |
|----------|-----------|-------------|
| `open` | `open(): void` | Open picker |
| `openFreeze` | `openFreeze(): void` | Open with frozen screen |
| `openClip` | `openClip(): void` | Open and copy to clipboard |
| `openFreezeClip` | `openFreezeClip(): void` | Open with freeze + clipboard |

### toaster

Send toast notifications.

| Function | Signature | Description |
|----------|-----------|-------------|
| `info` | `info(title, message, icon)` | Info toast |
| `success` | `success(title, message, icon)` | Success toast |
| `warn` | `warn(title, message, icon)` | Warning toast |
| `error` | `error(title, message, icon)` | Error toast |

### gameMode

Toggle game mode (disables animations, blur, shadows, gaps, border rounding; forces
`allow_tearing`). On Mango this writes `~/.config/mango/caelestia_gamemode.conf` and toggles a
`source=` line in `mango_core.conf` + `mmsg dispatch reload_config` — removing the source line
restores the user's original values, and the state survives shell restarts.

| Function | Signature | Description |
|----------|-----------|-------------|
| `toggle` | `toggle(): void` | Toggle game mode |
| `enable` | `enable(): void` | Enable game mode |
| `disable` | `disable(): void` | Disable game mode |
| `isEnabled` | `isEnabled(): bool` | Check game mode status |

### idleInhibitor

Inhibit idle/screensaver.

| Function | Signature | Description |
|----------|-----------|-------------|
| `toggle` | `toggle(): void` | Toggle idle inhibit |
| `enable` | `enable(): void` | Enable idle inhibit |
| `disable` | `disable(): void` | Disable idle inhibit |
| `isEnabled` | `isEnabled(): bool` | Check inhibit status |

### record

Screen recording (drives `gpu-screen-recorder` via the `caelestia` CLI).

| Function | Signature | Description |
|----------|-----------|-------------|
| `start` | `start(): void` | Start recording on the focused monitor |
| `startArgs` | `startArgs(extraArgs: string): void` | Start recording with whitespace-separated extra args (e.g. `"-r"` for region via slurp, `"-s"` for sound) |
| `stop` | `stop(): void` | Stop recording |
| `togglePause` | `togglePause(): void` | Pause/resume recording |
| `isRunning` | `isRunning(): string` | Check if recording (`"1"` / `"0"`) |
| `isPaused` | `isPaused(): string` | Check if paused (`"1"` / `"0"`) |

### mango

MangoWC compositor bridge.

| Function | Signature | Description |
|----------|-----------|-------------|
| `refreshDevices` | `refreshDevices(): void` | Refresh input devices |

---

## Configuration

Edit `~/.config/caelestia/shell.json` (must be created manually).

### Paths

| Key | Default | Description |
|-----|---------|-------------|
| `paths.wallpaperDir` | `~/Pictures/Wallpapers` | Wallpaper directory (source of truth for wallpaper `list`/`random`/`set`; can be set from Settings → Appearance → Background → Wallpaper folder) |
| `paths.lyricsDir` | `~/Music/lyrics/` | MPRIS lyrics directory |
| `paths.sessionGif` | `root:/assets/kurukuru.gif` | Session menu animation |
| `paths.mediaGif` | `root:/assets/bongocat.gif` | Media player animation |

### PFP

Profile picture for the dashboard is read from `~/.face`.

---

## Updating

### CMake install

```sh
cd caelestia-shell-mango
git pull
cmake --build build
sudo cmake --install build
```

### Nix install

```sh
cd caelestia-shell-mango
git pull
nix profile upgrade caelestia-shell
```

Or rebuild and reinstall:

```sh
nix build .#caelestia-shell && nix profile install .#caelestia-shell
```

Restart Quickshell after updating: `pkill quickshell && caelestia-shell -d`.

---

<div align="center">
  <sub>MangoWC port — not affiliated with the official Caelestia project.</sub>
</div>
