<h1 align="center">caelestia-shell <sub>MangoWC Port</sub></h1>

<div align="center">

![License](https://img.shields.io/github/license/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![Quickshell](https://img.shields.io/badge/quickshell-0.3-64DBB5?style=for-the-badge&labelColor=101418)
![wlroots](https://img.shields.io/badge/wlroots-0.20-7B68EE?style=for-the-badge&labelColor=101418)

</div>

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

---

## Install

### Build Dependencies

| Dependency | Needed for |
|------------|-----------|
| `cmake` (≥ 3.19), `ninja` | build system |
| `gcc` or `clang` | C++20 compiler |
| Qt6 (base + declarative) | Qt6 core, gui, qml, quick, network, dbus, sql, concurrent |
| Qt6 shadertools | shader compilation |
| `libqalculate` (dev) | in-app calculator |
| `libpipewire` (dev) | audio control |
| `libaubio` (dev) | audio beat detection |
| `libcava` or `cava` (dev) | audio visualiser |
| `material-symbols` font | icon set |
| `caskaydia-cove-nerd` font | monospace font |

Install the **development** packages for each dependency via your distro's package manager.

### Runtime Dependencies

| Package | Notes |
|---------|-------|
| `quickshell-git` | must be git version, not latest tagged |
| `mangowc` | with `mmsg` IPC support |
| `libpipewire` | audio control |
| `networkmanager` | network info |
| `lm-sensors` | hardware monitoring |
| `libcava` | audio visualiser |
| `swappy` | screenshot editor |
| `wl-clipboard` | clipboard access (`wl-copy`, `wl-paste`) |
| `libnotify` | desktop notifications (`notify-send`) |
| `procps` | process monitoring (`pidof`) |
| `util-linux` | disk info (`lsblk`) |
| `libxml2` | XKB layout parsing (`xmllint`) |
| `fprintd` | fingerprint authentication |
| `app2unit` | application launcher (converts desktop entries to systemd units) |
| `systemd` | session management (`loginctl`, `systemctl`) |
| `polkit` | privilege escalation (`pkexec`) |
| `fish` | default shell for calculator integration |
| `bash` | used throughout for shell commands |

> **Note:** Keyboard layout switching uses `setxkbmap` (tool-agnostic). No Hyprland dependencies remain.

### Optional

| Package | Notes |
|---------|-------|
| `libqalculate` | in-app calculator |
| `aubio` | audio beat detection |
| `ddcutil` | external monitor control |

| `caelestia-cli` | CLI helper |
| `gpu-screen-recorder` | screen recording (monitored via `pidof`) |
| `brightnessctl` | backlight control (needed if not using `ddcutil`) |

### System-wide Install

Builds the C++ QML plugin and installs everything system-wide.

```sh
git clone https://github.com/Ackerman-00/caelestia-shell-mango
cd caelestia-shell-mango

cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/ \
  -DINSTALL_QSCONFDIR=/etc/xdg/quickshell/caelestia

cmake --build build
sudo cmake --install build
```

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
bind=SUPER,v,spawn_shell,caelestia-shell ipc call drawers toggle sidebar
bind=SUPER,comma,spawn_shell,caelestia-shell ipc call controlCenter open
bind=SUPER,w,spawn_shell,caelestia-shell ipc call wallpaper openMenu
bind=SUPER,p,spawn_shell,caelestia-shell ipc call drawers toggle dashboard
bind=SUPER,l,spawn_shell,caelestia-shell ipc call lock lock
bind=SUPER+SHIFT,Print,spawn_shell,caelestia-shell ipc call picker open
bind=CTRL+ALT,w,spawn_shell,find ~/Pictures/wallpapers -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n1 | xargs -r caelestia-shell ipc call wallpaper set
bind=CTRL+ALT,Delete,spawn_shell,caelestia-shell ipc call drawers toggle session
```

> `spawn_shell` routes through `/bin/sh -c`, ensuring shell pipelines and argument handling work correctly. `caelestia-shell` is resolved via `env.conf` PATH.

---

## IPC Reference

All IPC commands go through `caelestia-shell` (in PATH after system-wide install):

```sh
caelestia-shell ipc call <target> <function> [args...]
```

### drawers

Toggle launcher, dashboard, sidebar, utilities, session, and OSD panels.

| Function | Signature | Description |
|----------|-----------|-------------|
| `toggle` | `toggle(drawer: string)` | Toggle a drawer (`launcher`, `dashboard`, `utilities`, `sidebar`, `session`, `osd`) |
| `list` | `list(): string` | List available drawer names |
| `isOpen` | `isOpen(drawer: string): string` | Check if a drawer is open (`"1"` / `"0"` / `"unknown"`) |

### controlCenter

Open the settings/control center window.

| Function | Signature | Description |
|----------|-----------|-------------|
| `open` | `open(): void` | Open control center |

### wallpaper

Manage wallpapers.

| Function | Signature | Description |
|----------|-----------|-------------|
| `get` | `get(): string` | Get current wallpaper path |
| `set` | `set(path: string)` | Set wallpaper by path |
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

Toggle game mode (disables animations, blur, shadows, gaps).

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
| `paths.wallpaperDir` | `~/Pictures/Wallpapers` | Wallpaper directory |
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
