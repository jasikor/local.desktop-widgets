import QtQuick
import qs.Commons

// One analog watch: a plain dial with an hour and a minute hand, twelve
// ticks, no numerals, no seconds, no date. The face is white while it is
// daytime in its city and black at night, so the four watches read as a
// "who is awake" map rather than four copies of the same clock.
Item {
  id: root

  property string city: ""
  property int hours: 0
  property int minutes: 0
  property real dialSize: Style.space(88)

  // Day runs 07:00-21:00 city time.
  readonly property bool daytime: hours >= 7 && hours < 21

  // Muted faces: warm paper rather than pure white, and charcoal rather than
  // black, so four dials on one card do not glare against the wallpaper.
  readonly property color faceColor: daytime ? "#ddd9cf" : "#2a2a2d"
  readonly property color inkColor: daytime ? "#1b1b19" : "#e9e7e0"
  readonly property color rimColor: daytime ? Util.alpha("#1b1b19", 0.25)
                                              : Util.alpha("#e9e7e0", 0.20)

  implicitWidth: dialSize
  implicitHeight: dialSize + Style.space(6) + label.implicitHeight
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

          x: (dial.width - width) / 2
          y: dial.height * 0.09
          width: major ? Math.max(1, dial.width * 0.02) : Math.max(1, dial.width * 0.012)
          height: major ? dial.height * 0.07 : dial.height * 0.045
          radius: width / 2
          color: root.inkColor
          opacity: major ? 0.8 : 0.45
        }
      }
    }

    // Hour hand. It creeps with the minutes even though the face only
    // repaints once a minute, so it is never an hour out at half past.
    Item {
      anchors.fill: parent
      rotation: (root.hours % 12) * 30 + root.minutes * 0.5

      Rectangle {
        x: (dial.width - width) / 2
        y: dial.height / 2 - height
        width: Math.max(2, dial.width * 0.035)
        height: dial.height * 0.25
        radius: width / 2
        color: root.inkColor
      }
    }

    // Minute hand: longer and thinner than the hour hand.
    Item {
      anchors.fill: parent
      rotation: root.minutes * 6

      Rectangle {
        x: (dial.width - width) / 2
        y: dial.height / 2 - height
        width: Math.max(1, dial.width * 0.02)
        height: dial.height * 0.37
        radius: width / 2
        color: root.inkColor
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.max(3, dial.width * 0.06)
      height: width
      radius: width / 2
      color: root.inkColor
    }
  }

  Text {
    id: label

    anchors.top: dial.bottom
    anchors.topMargin: Style.space(6)
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.city
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
