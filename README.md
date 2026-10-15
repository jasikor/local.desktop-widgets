# local.desktop-widgets

iPad-style desktop widget for [Omarchy](https://omarchy.org/): a single tile
that lives **on the desktop**, not in the bar. It sits on the wallpaper and is
naturally covered the moment a window is opened over it.

The tile shows:

- **Machine** — this machine's hostname (read from `/etc/hostname`, falling
  back to `$HOSTNAME`).
- **Workspaces** — a waybar-style row of workspace numbers where the label
  matches the key you press: `0` is workspace 10 and leads the row, then `1`–`9`
  (so it reads `0 1 2 3 …`). The focused workspace is filled with the accent
  colour, occupied ones are outlined, empty ones are dimmed. Click a number to
  switch. Workspaces `1`–`5` and `10` are always shown, extended with any other
  workspace you use.

## How it works

The tile is a `PanelWindow` on the Hyprland **`Bottom`** layer with
`ExclusionMode.Ignore`:

- `Bottom` sits above the wallpaper but **below every normal window**, so the
  tile is fully visible on an empty workspace and covered as soon as a window
  overlaps it — no show/hide logic required.
- `ExclusionMode.Ignore` means no screen space is reserved, so windows tile
  straight over the tile.
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
| `pad`      | `Style.space(12)`  | Inner padding of the tile.                              |
| `boxSize`  | `Style.space(24)`  | Side length of a workspace number box.                  |
| `boxGap`   | `Style.space(4)`   | Gap between workspace number boxes.                     |
| `margins.left` | `Style.space(48)` | Distance from the left screen edge.                  |

Which workspaces show mirrors the Omarchy bar's own widget — workspaces `1`–`5`
plus workspace `10` always, extended with any other workspace you use up to
`10`. The row is ordered `0`-first: workspace `10` is labelled `0` and leads,
then `1`–`9`, so each label matches the key that focuses it.

## Removal

```bash
omarchy plugin disable local.desktop-widgets
rm -rf ~/.config/omarchy/plugins/local.desktop-widgets
```

## License

MIT
