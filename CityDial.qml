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

  // Black-and-white pilot hands in the Mark XX leaf shape: a black frame
  // around a white lume inlay, with a constant frame width along the blade.
  readonly property color handFrameColor: "#111112"
  readonly property color lumeColor: "#f8f6ef"

  implicitWidth: dialSize
  implicitHeight: dialSize
  width: implicitWidth
  height: implicitHeight

  // One IWC-style hand, pointing at 12. A thin stem leaves the centre, flares
  // into a leaf-shaped blade, then tapers to a point. The lume is the blade
  // outline inset by a fixed border, so the black edge never grows thicker
  // towards the centre.
  component PilotHand: Item {
    id: hand

    anchors.fill: parent
    rotation: hand.angle

    property real angle: 0
    property real handLength: 0.29
    property real stemHalf: 0.013
    property real stemEnd: 0.075
    property real bladeHalf: 0.044
    property real shoulder: 0.14
    property real lumeStart: 0.085
    property real frameBorder: 0.010

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

        var length = hand.handLength
        var stem = hand.stemHalf
        var stemEnd = hand.stemEnd
        var blade = hand.bladeHalf
        var shoulder = hand.shoulder
        var border = hand.frameBorder

        // Half-width of the gold/black frame at a distance `h` from centre.
        function frameHalfAt(h) {
          if (h <= stemEnd) return stem
          if (h <= shoulder) return stem + (blade - stem) * (h - stemEnd) / (shoulder - stemEnd)
          return blade * (length - h) / (length - shoulder)
        }

        ctx.clearRect(0, 0, width, height)

        // Frame: stem, flare, long taper to the point.
        ctx.beginPath()
        ctx.moveTo(cx - stem * d, cy + 0.012 * d)
        ctx.lineTo(cx - stem * d, cy - stemEnd * d)
        ctx.lineTo(cx - blade * d, cy - shoulder * d)
        ctx.lineTo(cx, cy - length * d)
        ctx.lineTo(cx + blade * d, cy - shoulder * d)
        ctx.lineTo(cx + stem * d, cy - stemEnd * d)
        ctx.lineTo(cx + stem * d, cy + 0.012 * d)
        ctx.closePath()
        ctx.fillStyle = handCanvas.frameColour
        ctx.fill()

        // Lume: the same blade inset by a constant border. It starts in a
        // point on the axis and ends where the frame has narrowed to twice
        // the border, leaving a pointed frame tip.
        var tip = length - border * (length - shoulder) / blade
        var start = hand.lumeStart
        var step = 0.004
        var h

        ctx.beginPath()
        ctx.moveTo(cx, cy - start * d)
        for (h = start + step; h < tip; h += step) {
          var half = Math.max(0, frameHalfAt(h) - border)
          ctx.lineTo(cx - half * d, cy - h * d)
        }
        ctx.lineTo(cx, cy - tip * d)
        for (h = tip - step; h > start; h -= step) {
          var halfBack = Math.max(0, frameHalfAt(h) - border)
          ctx.lineTo(cx + halfBack * d, cy - h * d)
        }
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
      bladeHalf: 0.044
      shoulder: 0.14
      lumeStart: 0.085
      frameBorder: 0.010
    }

    // Minute hand: longer and narrower, same leaf profile and border.
    PilotHand {
      angle: root.minutes * 6
      handLength: 0.39
      stemHalf: 0.010
      stemEnd: 0.10
      bladeHalf: 0.030
      shoulder: 0.16
      lumeStart: 0.115
      frameBorder: 0.0075
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.max(5, dial.width * 0.08)
      height: width
      radius: width / 2
      color: root.handFrameColor

      Rectangle {
        anchors.centerIn: parent
        width: Math.max(2, dial.width * 0.022)
        height: width
        radius: width / 2
        color: root.lumeColor
      }
    }
  }
}
