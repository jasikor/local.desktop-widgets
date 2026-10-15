import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// A single desktop widget: laptop name on top, a waybar-style workspace row
// underneath, in one tile that lives *on* the desktop.
//
// The tile is a PanelWindow on the *Bottom* layer pinned to the left edge and
// centred vertically, sized to its content so it never blocks clicks meant for
// the rest of the desktop. Being on the Bottom layer it draws above the
// wallpaper but below every normal window: fully visible on an empty
// workspace, naturally covered the moment a window is opened over it.
Item {
  id: root

  readonly property int pad: Style.space(12)
  readonly property int boxSize: Style.space(24)
  readonly property int boxGap: Style.space(4)

  // Machine name. Env first, /etc/hostname authoritative fallback.
  property string hostname: Quickshell.env("HOSTNAME") || ""

  FileView {
    path: "/etc/hostname"
    watchChanges: false
    printErrors: false
    onLoaded: root.hostname = String(text() || "").trim()
  }

  // Workspaces 1-5 always, plus any existing workspace up to 10 (matches the
  // Omarchy bar's own workspace widget so the two agree).
  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  Process {
    id: focusProc
    property string target: ""
    running: false
    command: ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = \"" + target + "\" })"]
  }

  function focusWorkspace(id) {
    focusProc.target = String(id)
    focusProc.running = true
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window
      required property var modelData

      screen: modelData
      // Left edge, vertically centred: no top/bottom anchor centres the axis.
      anchors { left: true; right: false; top: false; bottom: false }
      margins.left: Style.space(48)
      implicitWidth: card.width
      implicitHeight: card.height
      color: "transparent"

      WlrLayershell.namespace: "desktop-widgets"
      WlrLayershell.layer: WlrLayer.Bottom
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      BorderSurface {
        id: card

        width: content.implicitWidth + root.pad * 2
        height: content.implicitHeight + root.pad * 2

        color: Util.alpha(Color.popups.background, 0.9)
        borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
        radius: Style.cornerRadius

        Column {
          id: content
          anchors.centerIn: parent
          spacing: Style.space(8)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.hostname
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
            font.bold: true
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.boxGap

            Repeater {
              model: root.workspaceIds()

              Rectangle {
                id: wsBox
                required property int modelData

                readonly property var workspace: root.workspaceById(modelData)
                readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
                readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
                readonly property bool hovered: hoverHandler.hovered

                width: root.boxSize
                height: root.boxSize
                radius: Math.min(Style.cornerRadius, height / 2)
                color: focused ? Color.accent
                     : hovered ? Util.alpha(Color.foreground, 0.15)
                     : "transparent"
                border.width: !focused && occupied ? 1 : 0
                border.color: Util.alpha(Color.foreground, 0.35)

                Text {
                  anchors.centerIn: parent
                  // Displayed 0-based: workspace 1 reads "0", ..., 10 reads "9".
                  text: String(wsBox.modelData - 1)
                  color: wsBox.focused ? Color.background
                       : wsBox.occupied || wsBox.hovered ? Color.foreground
                       : Color.muted
                  font.family: Style.font.family
                  font.pixelSize: Style.font.body
                  font.bold: wsBox.focused
                }

                HoverHandler {
                  id: hoverHandler
                  cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: root.focusWorkspace(wsBox.modelData)
                }
              }
            }
          }
        }
      }
    }
  }
}
