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

  // ---- World clocks. Four cities, four analog dials. Times come from the
  //      system zoneinfo rather than hardcoded UTC offsets, so daylight
  //      saving is whatever the machine says it is — Toronto and Miami share
  //      a zone, Zurich has its own, Tokyo never changes.
  readonly property var cities: [
    { name: "Zurich", zone: "Europe/Zurich" },
    { name: "Toronto", zone: "America/Toronto" },
    { name: "Miami", zone: "America/New_York" },
    { name: "Tokyo", zone: "Asia/Tokyo" }
  ]

  // Wall-clock hours/minutes per city, in `cities` order. Seeded with local
  // time so the first paint is a plausible clock rather than 12:00.
  property var zoneTimes: root.seedZoneTimes()

  function seedZoneTimes() {
    var now = new Date()
    var seed = []
    for (var i = 0; i < cities.length; i++) seed.push({ hours: now.getHours(), minutes: now.getMinutes() })
    return seed
  }

  function refreshZoneTimes() {
    zonesProc.running = true
  }

  // One process for all four cities: four tiny `date` calls, once a minute.
  // Keeping it to a single process avoids four timers drifting apart. The
  // command is built from `cities`, so the zone list has one source of truth.
  Process {
    id: zonesProc
    running: false
    command: {
      var calls = []
      for (var i = 0; i < root.cities.length; i++)
        calls.push("TZ=\"" + root.cities[i].zone + "\" date '+%H %M'")
      return ["sh", "-c", calls.join("; ")]
    }

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text).trim().split("\n")
        if (lines.length !== root.cities.length) return

        var parsed = []
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].trim().split(/\s+/)
          var h = parseInt(parts[0], 10)
          var m = parseInt(parts[1], 10)
          if (isNaN(h) || isNaN(m)) return
          parsed.push({ hours: h, minutes: m })
        }
        root.zoneTimes = parsed
      }
    }
  }

  SystemClock {
    precision: SystemClock.Minutes
    onDateChanged: root.refreshZoneTimes()
  }

  Component.onCompleted: root.refreshZoneTimes()

  // All ten workspaces, always shown in two rows of five. Ordered 0-first so
  // the label matches the key you press: "0" is workspace 10 and leads, then
  // "1".."9" are workspaces 1..9. Laid out 5-per-row -> "0 1 2 3 4" / "5 6 7 8 9".
  function workspaceIds() {
    return [10, 1, 2, 3, 4, 5, 6, 7, 8, 9]
  }

  function workspaceLabel(id) {
    return id === 10 ? "0" : String(id)
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

          Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 5
            rowSpacing: root.boxGap
            columnSpacing: root.boxGap

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
                  text: root.workspaceLabel(wsBox.modelData)
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

          // Four watches, one per city, stacked below the workspaces.
          Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(12)

            Repeater {
              model: root.cities

              CityDial {
                required property var modelData
                required property int index

                city: modelData.name
                hours: root.zoneTimes[index] ? root.zoneTimes[index].hours : 0
                minutes: root.zoneTimes[index] ? root.zoneTimes[index].minutes : 0
              }
            }
          }
        }
      }
    }
  }
}
