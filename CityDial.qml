import QtQuick
import qs.Commons

// One analog watch: a plain dial with an hour and a minute hand, twelve
// ticks, no numerals, no seconds, no date. The face is dim cream while it is
// daytime in its city and dark grey at night, so the four watches read as a
// "who is awake" map rather than four copies of the same clock.
Item {
  id: root

  property string city: ""
  property int hours: 0
  property int minutes: 0
  property real dialSize: Style.space(100)

  // Day runs 07:00-21:00 city time.
  readonly property bool daytime: hours >= 7 && hours < 21

  // Muted faces: warm paper rather than white, and charcoal rather than
  // black, so four dials on one card do not glare against the wallpaper.
  readonly property color faceColor: daytime ? "#cbc8bf" : "#2a2a2d"
  readonly property color inkColor: daytime ? "#1b1b19" : "#e9e7e0"
  readonly property color rimColor: daytime ? Util.alpha("#1b1b19", 0.25)
                                              : Util.alpha("#e9e7e0", 0.20)

  // IWC-pilot-style hands: a dark frame around a bright lume insert, with a
  // straight blade that tapers into a pointed tip.
  readonly property color handFrameColor: daytime ? "#161614" : "#08080a"
  readonly property color lumeColor: daytime ? "#f3f0e7" : "#eeece5"

  implicitWidth: dialSize
  implicitHeight: dialSize
  width: implicitWidth
  height: implicitHeight

  // A sword hand pointing at 12, measured in fractions of the dial so the
  // same component serves both the short hour hand and the long minute hand.
  component PilotHand: Item {
    id: hand

    anchors.fill: parent
    rotation: hand.angle

    property real angle: 0
    property real handLength: 0.235
    property real shoulder: 0.165
    property real baseHalf: 0.027
    property real lumeHalf: 0.015
    property real lumeShoulder: 0.185
    property real lumeTip: 0.215

    Canvas {
      id: handCanvas

      anchors.fill: parent

      property color frameColour: root.handFrameColor
      property color lumeColour: root.lumeColor

      onFrameColourChanged: requestPaint()
      onLumeColourChanged: requestPaint()
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      Component.onCompleted: requestPaint()

      onPaint: {
        var ctx = getContext("2d")
        var d = width
        var cx = d / 2
        var cy = d / 2

        ctx.clearRect(0, 0, width, height)

        function blade(half, shoulderAt, tipAt, tailAt, colour) {
          ctx.beginPath()
          ctx.moveTo(cx - half * d, cy + tailAt * d)
          ctx.lineTo(cx - half * d, cy - shoulderAt * d)
          ctx.lineTo(cx, cy - tipAt * d)
          ctx.lineTo(cx + half * d, cy - shoulderAt * d)
          ctx.lineTo(cx + half * d, cy + tailAt * d)
          ctx.closePath()
          ctx.fillStyle = colour
          ctx.fill()
        }

        blade(hand.baseHalf, hand.shoulder, hand.handLength, 0.012, handCanvas.frameColour)
        blade(hand.lumeHalf, hand.lumeShoulder, hand.lumeTip, 0.006, handCanvas.lumeColour)
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
      handLength: 0.235
      shoulder: 0.165
      baseHalf: 0.027
      lumeHalf: 0.015
      lumeShoulder: 0.185
      lumeTip: 0.212
    }

    // Minute hand: longer, narrower, same sword profile.
    PilotHand {
      angle: root.minutes * 6
      handLength: 0.35
      shoulder: 0.28
      baseHalf: 0.018
      lumeHalf: 0.009
      lumeShoulder: 0.31
      lumeTip: 0.336
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.max(4, dial.width * 0.07)
      height: width
      radius: width / 2
      color: root.handFrameColor
    }
  }
}
