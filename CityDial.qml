import QtQuick
import qs.Commons

// One analog watch: hour and minute batons, twelve ticks, no numerals, no
// seconds, no date, plus a small 24-hour GMT subdial at four-thirty that
// straddles the dial edge. The 12-hour hands cannot say whether it is morning
// or evening; the subdial hand can, because it sweeps once a day: 00:00 at the
// top, 06:00 on the right, 12:00 at the bottom and 18:00 on the left. One
// charcoal face at every hour, so the four watches keep the same contrast
// whatever time it is in their city.
Item {
  id: root

  property string city: ""
  property int hours: 0
  property int minutes: 0
  property real dialSize: Style.space(100)

  // Muted faces: charcoal rather than black, and warm off-white ink, so four
  // dials on one card do not glare against the wallpaper.
  readonly property color faceColor: "#2a2a2d"
  readonly property color inkColor: "#e9e7e0"
  readonly property color rimColor: Util.alpha(inkColor, 0.28)

  // The GMT subdial hand is a shade dimmer than the batons: shape and size
  // already set it apart, so it does not need a second colour on the dial.
  readonly property color gmtColor: Util.alpha(inkColor, 0.85)

  // Minutes since local midnight, 0..1439, for the 24-hour subdial hand.
  readonly property real dayMinutes: (hours % 24) * 60 + minutes

  // GMT subdial at four-thirty: a small circle that sits half on the dial and
  // half over the card, with its own quarter dots.
  readonly property real subdialSize: dialSize * 0.26
  readonly property real subdialCenterX: dialSize * 0.85
  readonly property real subdialCenterY: dialSize * 0.85
  readonly property color subdialFaceColor: "#232325"
  readonly property color subdialRimColor: Util.alpha(inkColor, 0.32)
  readonly property real subdialDotRadius: subdialSize / 2 - Style.space(2)

  implicitWidth: dialSize
  implicitHeight: dialSize
  width: implicitWidth
  height: implicitHeight

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

          // Four and five o'clock give way to the GMT subdial straddling the
          // rim between them.
          visible: index !== 4 && index !== 5
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

    // GMT subdial: a small circle straddling the rim at four-thirty, with one
    // thin 24-hour hand and four quarter dots for its scale. Midnight at the
    // top, one turn per day, so the right half is morning and the left half
    // evening.
    Item {
      id: gmtSubdial

      width: root.subdialSize
      height: width
      x: root.subdialCenterX - width / 2
      y: root.subdialCenterY - height / 2

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.subdialFaceColor
        border.width: Math.max(1, Style.space(1))
        border.color: root.subdialRimColor
      }

      Repeater {
        model: 4

        Item {
          required property int index

          anchors.fill: parent
          rotation: index * 90

          Rectangle {
            x: (gmtSubdial.width - width) / 2
            y: gmtSubdial.height / 2 - root.subdialDotRadius - height / 2
            width: Math.max(2, Math.round(root.subdialSize * 0.07))
            height: width
            radius: width / 2
            color: root.inkColor
            opacity: 0.7
          }
        }
      }

      Item {
        anchors.fill: parent
        rotation: root.dayMinutes / 1440 * 360

        Rectangle {
          x: (gmtSubdial.width - width) / 2
          y: gmtSubdial.height / 2 - height
          width: Math.max(2, Math.round(root.subdialSize * 0.06))
          height: root.subdialSize * 0.40
          radius: width / 2
          color: root.gmtColor
        }
      }

      Rectangle {
        anchors.centerIn: parent
        width: Math.max(2, Math.round(root.subdialSize * 0.075))
        height: width
        radius: width / 2
        color: root.gmtColor
      }
    }

    // Hour hand: a plain solid baton. It creeps with the minutes even though
    // the face only repaints once a minute, so it is never an hour out at
    // half past.
    Item {
      anchors.fill: parent
      rotation: (root.hours % 12) * 30 + root.minutes * 0.5

      Rectangle {
        x: (dial.width - width) / 2
        y: dial.height / 2 - height
        width: Math.max(2, Math.round(dial.width * 0.04))
        height: dial.height * 0.26
        radius: width / 2
        color: root.inkColor
      }
    }

    // Minute hand: longer and thinner, same baton shape.
    Item {
      anchors.fill: parent
      rotation: root.minutes * 6

      Rectangle {
        x: (dial.width - width) / 2
        y: dial.height / 2 - height
        width: Math.max(1, Math.round(dial.width * 0.026))
        height: dial.height * 0.37
        radius: width / 2
        color: root.inkColor
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.max(3, Math.round(dial.width * 0.04))
      height: width
      radius: width / 2
      color: root.inkColor
    }
  }
}
