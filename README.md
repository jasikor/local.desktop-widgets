# local.desktop-widgets

iPad-style desktop widgets for [Omarchy](https://omarchy.org/): small tiles
that live **on the desktop**, not in the bar. They sit on the wallpaper and are
naturally covered the moment a window is opened over them.

Two tiles ship today:

- **Machine** — this machine's hostname (read from `/etc/hostname`, falling
  back to `$HOSTNAME`).
- **Workspaces** — a waybar-style row of workspace numbers that doubles as a
  switcher: the focused workspace is filled with the accent colour, occupied
  ones are outlined, empty ones are dimmed. Click a number to switch.

## How it works

Each tile is a `PanelWindow` on the Hyprland **`Bottom`** layer with
`ExclusionMode.Ignore`:

- `Bottom` sits above the wallpaper but **below every normal window**, so the
  tiles are fully visible on an empty workspace and covered as soon as a window
  overlaps them — no show/hide logic required.
- `ExclusionMode.Ignore` means no screen space is reserved, so windows tile
  straight over the tiles.
- The window is sized to its content and pinned to the left edge, vertically
  centred, so it never blocks clicks meant for the rest of the desktop.

## Install

```bash
git clone https://github.com/jasikor/local.desktop-widgets.git \
  ~/.config/omarchy/plugins/local.desktop-widgets

omarchy plugin enable local.desktop-widgets
omarchy restart shell
```

Or let Omarchy clone and enable it from the URL:

```bash
omarchy plugin add https://github.com/jasikor/local.desktop-widgets --enable
```

## Configure

The layout is deliberately small; adjust the constants at the top of
`DesktopWidgets.qml` and the shell hot-reloads on save:

| Constant   | Default            | Description                                             |
|------------|--------------------|---------------------------------------------------------|
| `pad`      | `Style.space(12)`  | Inner padding of each tile.                             |
| `boxSize`  | `Style.space(24)`  | Side length of a workspace number box.                  |
| `boxGap`   | `Style.space(4)`   | Gap between workspace number boxes.                     |
| `margins.left` | `Style.space(48)` | Distance from the left screen edge.                  |

Which workspaces show follows the Omarchy bar's own widget: `1`–`5` always,
plus any existing workspace up to `10`.

## Removal

```bash
omarchy plugin disable local.desktop-widgets
rm -rf ~/.config/omarchy/plugins/local.desktop-widgets
```

## License

MIT
