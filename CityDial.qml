import QtQuick
import qs.Commons

// One analog watch: a plain dial with an hour and a minute hand, twelve
// ticks, no numerals, no seconds, no date. The face is dim warm grey while it
// is daytime in its city and dark grey at night, so the four watches read as
// a "who is awake" map rather than four copies of the same clock.
Item {
  id: root

  property string city: ""
  property int hours: 0
  property int minutes: 0
  property real dialSize: Style.space(100)

  // Day runs 07:00-21:00 city time.
  readonly property bool daytime: hours >= 7 && hours < 21

  // Muted faces: warm stone rather than white, and charcoal rather than
  // black, so four dials on one card do not glare against the wallpaper.
  readonly property color faceColor: daytime ? "#a3a095" : "#2a2a2d"
  readonly property color inkColor: daytime ? "#1b1b19" : "#e9e7e0"
  readonly property color rimColor: daytime ? Util.alpha("#1b1b19", 0.25)
                                              : Util.alpha("#e9e7e0", 0.20)

  // IWC Mark XX "Le Petit Prince" hands: gold-plated frames filled with
  // Super-LumiNova. Daytime needs a deeper bronze to stay legible on the
  // stone face; at night the gold is allowed to shine.
  readonly property color handFrameColor: daytime ? "#6f5327" : "#c9a45c"
  readonly property color lumeColor: "#fbf9f0"

  implicitWidth: dialSize
  implicitHeight: dialSize
  width: implicitWidth
  height: implicitHeight

  // One IWC-style hand, pointing at 12. Lengths are fractions of the dial:
  // a thin gold stem leaves the centre, then flares into a leaf-shaped blade
  // whose pointed luminous inlay tapers to a tip short of the gold point.
  component PilotHand: Item {
    id: hand

    anchors.fill: parent
    rotation: hand.angle

    property real angle: 0
    property real handLength: 0.285
    property real stemHalf: 0.014
    property real stemEnd: 0.12
    property real bladeHalf: 0.038
    property real shoulder: 0.155
    property real lumeStart: 0.13
    property real lumeHalf: 0.026
    property real lumeShoulder: 0.19
    property real lumeTip: 0.272

    Canvas {
      id: handCanvas

      anchors.fill: parent

      property color frameColour: root.handFrameColor

      onFrameColourChanged: requestPaint()
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      Component.onCompleted: requestPaint()

      onPaint: {
        var ctx = getContext("2d")
        var d = width
        var cx = d / 2
        var cy = d / 2

        ctx.clearRect(0, 0, width, height)

        // Gold frame: stem, flare, then a long taper to the point.
        ctx.beginPath()
        ctx.moveTo(cx - hand.stemHalf * d, cy + 0.012 * d)
        ctx.lineTo(cx - hand.stemHalf * d, cy - hand.stemEnd * d)
        ctx.lineTo(cx - hand.bladeHalf * d, cy - hand.shoulder * d)
        ctx.lineTo(cx, cy - hand.handLength * d)
        ctx.lineTo(cx + hand.bladeHalf * d, cy - hand.shoulder * d)
        ctx.lineTo(cx + hand.stemHalf * d, cy - hand.stemEnd * d)
        ctx.lineTo(cx + hand.stemHalf * d, cy + 0.012 * d)
        ctx.closePath()
        ctx.fillStyle = handCanvas.frameColour
        ctx.fill()

        // Luminous inlay, pointed at both ends like the Mark XX hand.
        ctx.beginPath()
        ctx.moveTo(cx, cy - hand.lumeStart * d)
        ctx.lineTo(cx - hand.lumeHalf * d, cy - hand.lumeShoulder * d)
        ctx.lineTo(cx, cy - hand.lumeTip * d)
        ctx.lineTo(cx + hand.lumeHalf * d, cy - hand.lumeShoulder * d)
        ctx.closePath()
        ctx.fillStyle = root.lumeColor
        ctx.fill()
      }
    }
  }

  Item {
    id: dial

    width: root.dialSize
    height: root.dialSize
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: root.faceColor
      border.width: Math.max(1, Style.space(1))
      border.color: root.rimColor
    }

    // Twelve ticks, quarter marks a touch longer and stronger. Still no
    // numerals: the dial is meant to be read at a glance, not studied.
    Repeater {
      model: 12

      Item {
        required property int index

        anchors.fill: parent
        rotation: index * 30

        Rectangle {
          readonly property bool major: index % 3 === 0

          x: (dial.width - width) / 2
          y: dial.height * 0.09
          width: major ? Math.max(1, dial.width * 0.022) : Math.max(1, dial.width * 0.012)
          height: major ? dial.height * 0.07 : dial.height * 0.045
          radius: width / 2
          color: root.inkColor
          opacity: major ? 0.8 : 0.45
        }
      }
    }

    // City name where a watch brand would normally sit: between the 12 mark
    // and the centre. Under the hands, so it never hides the time.
    Text {
      id: cityLabel

      anchors.horizontalCenter: parent.horizontalCenter
      y: dial.height * 0.19
      text: root.city
      color: Util.alpha(root.inkColor, 0.9)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: Math.max(0.5, dial.width * 0.006)
    }

    // Hour hand. It creeps with the minutes even though the face only
    // repaints once a minute, so it is never an hour out at half past.
    PilotHand {
      angle: (root.hours % 12) * 30 + root.minutes * 0.5
      handLength: 0.29
      stemHalf: 0.013
      stemEnd: 0.075
      bladeHalf: 0.042
      shoulder: 0.14
      lumeStart: 0.10
      lumeHalf: 0.030
      lumeShoulder: 0.15
      lumeTip: 0.278
    }

    // Minute hand: longer and only slightly narrower, with the same flare.
    PilotHand {
      angle: root.minutes * 6
      handLength: 0.39
      stemHalf: 0.010
      stemEnd: 0.10
      bladeHalf: 0.026
      shoulder: 0.16
      lumeStart: 0.125
      lumeHalf: 0.015
      lumeShoulder: 0.17
      lumeTip: 0.378
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.max(5, dial.width * 0.085)
      height: width
      radius: width / 2
      color: root.handFrameColor
    }
  }
}
