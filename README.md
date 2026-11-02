# macmono

My personal dotfiles: a **macOS-style monochrome shell** built with [Quickshell](https://quickshell.org) on top of [Hyprland](https://hyprland.org) (Wayland).

Every color in this shell is pure gray (R=G=B), with no accent colors at all. The look is minimal and clean, and everything is controlled from a single theme file.

> Used daily on **CachyOS**. Tested on **Hyprland 0.57** and **Quickshell 0.3.2**.

<!-- Drop a screenshot here, for example:
![macmono](assets/screenshot.png)
-->

## Repo layout

```
macmono/
└── .config/
    ├── hypr/                 # Hyprland config (Lua) + hypridle + hyprlock
    │   ├── hyprland.lua
    │   ├── hypridle.conf
    │   ├── hyprlock.conf
    │   ├── hyprland/         # base config (based on end-4's dots)
    │   └── custom/           # my personal overrides (env, execs, keybinds, rules, variables)
    └── quickshell/
        └── macmono/          # the shell itself
            ├── shell.qml     # entry point
            ├── core/         # Theme, Settings, Shortcuts, Sys + scripts (record, session, thumbs)
            ├── menubar/      # menu bar + system tray
            ├── launcher/     # launcher + workspace overview
            ├── cc/           # control center (wifi, bluetooth, battery, media, power, tools)
            ├── notif/        # notifications
            ├── osd/          # volume / brightness OSD
            ├── clipboard/    # clipboard manager (cliphist)
            ├── calendar/     # calendar
            ├── media/        # media popup
            ├── capture/      # area screenshot
            ├── cheatsheet/   # keybind cheatsheet
            ├── power/        # power menu
            ├── lock/         # lock screen
            ├── wallpaper/    # wallpaper
            ├── services/     # audio and Hyprland overview services
            └── ui/           # reusable UI components
```

## Features

- **Menu bar** in macOS style, with a full system tray
- **Launcher** (tap `Super`) and workspace **overview**
- **Control Center**: WiFi, Bluetooth, battery, media controls, power actions, and a tools panel
- **Notifications** and **OSD** (volume / brightness)
- **Clipboard manager** powered by `cliphist`
- **Area screenshot** and **screen recording** (`wf-recorder`)
- **Calendar**, **media popup**, keybind **cheatsheet**, and **power menu**
- **Lock screen** (`hyprlock`) plus idle auto-lock (`hypridle`)
- **Centralized theme**: all colors, radii, and font sizes live in `core/Theme.qml`

## Base config

macmono runs on top of the [end-4 / dots-hyprland](https://github.com/end-4/dots-hyprland) config. Shortcut names and keybinds are intentionally kept identical, so `Super`, `Super+N`, `Super+L`, `Ctrl+Super+T`, `Super+Shift+S`, idle auto-lock, and the rest plug straight into macmono.

The active shell is selected with the `qsConfig` variable in `hypr/custom/variables.lua`:

```lua
hl.env("qsConfig", "macmono")  -- change to "ii" to go back to end-4's shell
```

## Dependencies

Required:

- `hyprland`, `hyprlock`, `hypridle`
- `quickshell`
- `pipewire` (audio), `networkmanager` (`nmcli`), `bluez` (Bluetooth), `upower` (battery)
- `brightnessctl`
- `libnotify` (`notify-send`)
- A polkit agent (any one): `polkit-kde-agent`, `hyprpolkitagent`, or `polkit-gnome`

For specific features:

- `grim`, `imagemagick` (`magick`), `wl-clipboard` (`wl-copy`): area screenshot
- `cliphist`: clipboard manager
- `wf-recorder`: screen recording (GPU encoding via VA-API when available)
- `systemsettings`, `gnome-control-center`, or `better-control`: settings app (`Super+I`)

Install on Arch / CachyOS:

```bash
sudo pacman -S hyprland hyprlock hypridle quickshell \
  networkmanager bluez bluez-utils upower brightnessctl libnotify \
  grim imagemagick wl-clipboard cliphist wf-recorder
```

## Installation

There is no installer, so installation is manual. **Back up your existing config first.**

```bash
git clone https://github.com/esrahmn/macmono-shell.git
cd macmono-shell

# back up
mv ~/.config/hypr ~/.config/hypr.bak
mv ~/.config/quickshell ~/.config/quickshell.bak

# install
cp -r macmono/.config/hypr ~/.config/
cp -r macmono/.config/quickshell ~/.config/
```

Or use [GNU Stow](https://www.gnu.org/software/stow/) to symlink everything and make updates easy:

```bash
stow -t ~ macmono
```

Then log back into Hyprland, or launch the shell directly:

```bash
qs -c macmono
```

> If you don't have end-4's config yet, `hypr/hyprland/` in this repo already ships the base config. If you already use end-4's dots, you only need to copy `hypr/custom/` and the `quickshell/macmono/` folder.

## Key bindings

| Keybind | Action |
| --- | --- |
| `Super` (tap) | Toggle launcher |
| `Super + Tab` | Workspace overview |
| `Super + V` | Clipboard manager |
| `Super + N` | Toggle right sidebar |
| `Super + M` | Media controls |
| `Super + /` | Keybind cheatsheet |
| `Super + J` | Toggle bar |
| `Super + L` | Lock screen |
| `Super + Shift + S` | Area screenshot |
| `Ctrl + Super + T` | Wallpaper picker |
| `Ctrl + Super + R` | Reload shell |
| `Ctrl + Alt + Delete` | Session / power menu |

The full list is in `hypr/hyprland/keybinds.lua`. Put personal keybinds in `hypr/custom/keybinds.lua`.

## Customization

- **Appearance**: edit `quickshell/macmono/core/Theme.qml`, then reload with `Ctrl + Super + R`. Other QML files should just use `Theme.<name>`, so don't hardcode colors or sizes in components.
- **Keybinds**: `hypr/custom/keybinds.lua`
- **Autostart**: `hypr/custom/execs.lua`
- **Window rules**: `hypr/custom/rules.lua`
- **Variables**: `hypr/custom/variables.lua`

## Credits

macmono wouldn't exist without the work of these people and projects. Huge thanks to all of them.

**Core**

- [Quickshell](https://quickshell.org) by [@outfoxxed](https://github.com/outfoxxed): the toolkit that powers the whole shell
- [Hyprland](https://github.com/hyprwm/Hyprland) by [@vaxerski](https://github.com/vaxerski) (Vaxry) and the [hyprwm](https://github.com/hyprwm) contributors: the compositor
- [hyprlock](https://github.com/hyprwm/hyprlock) and [hypridle](https://github.com/hyprwm/hypridle) by [@vaxerski](https://github.com/vaxerski) and the hyprwm contributors: lock screen and idle daemon
- [end-4 / dots-hyprland](https://github.com/end-4/dots-hyprland) by [@end-4](https://github.com/end-4): the base config, keybind layout, and a big source of inspiration

**Tools and services used**

- [cliphist](https://github.com/sentriz/cliphist) by [@sentriz](https://github.com/sentriz): clipboard history
- [grim](https://gitlab.freedesktop.org/emersion/grim) by [@emersion](https://github.com/emersion) (Simon Ser): screenshots
- [wf-recorder](https://github.com/ammen99/wf-recorder) by [@ammen99](https://github.com/ammen99): screen recording
- [wl-clipboard](https://github.com/bugaevc/wl-clipboard) by [@bugaevc](https://github.com/bugaevc): Wayland clipboard utilities
- [brightnessctl](https://github.com/Hummer12007/brightnessctl) by [@Hummer12007](https://github.com/Hummer12007): brightness control
- [ImageMagick](https://imagemagick.org): image processing for screenshots and thumbnails
- [PipeWire](https://pipewire.org), [NetworkManager](https://networkmanager.dev), [BlueZ](https://www.bluez.org), and [UPower](https://upower.freedesktop.org): audio, network, Bluetooth, and battery services
- [GNU Stow](https://www.gnu.org/software/stow/): symlink management

**Design inspiration**

- macOS, for the menu bar, Control Center, and overall look and feel

## License

[GPL-3.0](LICENSE)
