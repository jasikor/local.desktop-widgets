import QtQuick
import qs.Commons

// One analog watch: hour and minute batons, eleven ticks, no seconds, plus a
// date window at three o'clock. The 12-hour hands cannot say whether it is
// morning or evening, so the twelve o'clock mark is a sun during the day
// (06:00-17:59) and a moon during the night (18:00-05:59). One black face at
// every hour, so all five watches keep the same contrast whatever time it is
// in their city.
Item {
  id: root

  property string city: ""
  property int hours: 0
  property int minutes: 0
  property int day: 1
  property real dialSize: Style.space(100)

  // Black faces with warm off-white ink, so four dials on one card stay quiet
  // against the wallpaper.
  readonly property color faceColor: "#000000"
  readonly property color inkColor: "#e9e7e0"

  // Date window at three o'clock, on the city's own calendar day.
  readonly property real dateWidth: dialSize * 0.18
  readonly property real dateHeight: dialSize * 0.14
  readonly property real dateCenterX: dialSize * 0.87
  readonly property color recessColor: "#000000"
  readonly property color recessRimColor: Util.alpha(inkColor, 0.32)

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
    }

    // Eleven ticks, quarter marks a touch longer and stronger. Twelve o'clock
    // is a numeral instead, so the dial still reads at a glance.
    Repeater {
      model: 12

      Item {
        required property int index

        anchors.fill: parent
        rotation: index * 30

        Rectangle {
          readonly property bool major: index % 3 === 0

          // Twelve o'clock is the sun/moon mark and three o'clock belongs to
          // the date window, so neither gets a tick.
          visible: index !== 0 && index !== 3
          x: (dial.width - width) / 2
          y: dial.height * 0.055
          width: major ? Math.max(1, dial.width * 0.022) : Math.max(1, dial.width * 0.012)
          height: major ? dial.height * 0.07 : dial.height * 0.045
          radius: width / 2
          color: root.inkColor
          opacity: major ? 0.8 : 0.45
        }
      }
    }

    // Twelve o'clock: a sun through the day (06:00-17:59) and a moon through
    // the night (18:00-05:59), so the 12-hour hands never leave am/pm in
    // doubt. Drawn from primitives rather than font glyphs, so it keeps the
    // dial's ink exactly and scales with the dial.
    Item {
      id: dayMark

      readonly property bool night: root.hours < 6 || root.hours >= 18
      readonly property real markSize: dial.width * 0.17

      width: markSize
      height: markSize
      x: (dial.width - width) / 2
      y: dial.height * 0.035

      // Sun: a filled disc with eight rounded rays.
      Item {
        anchors.fill: parent
        visible: !dayMark.night

        Rectangle {
          anchors.centerIn: parent
          width: parent.width * 0.42
          height: width
          radius: width / 2
          color: root.inkColor
        }

        Repeater {
          model: 8

          Item {
            required property int index

            anchors.fill: parent
            rotation: index * 45

            Rectangle {
              x: (parent.width - width) / 2
              y: 0
              width: Math.max(1, Math.round(parent.width * 0.055))
              height: parent.height * 0.19
              radius: width / 2
              color: root.inkColor
            }
          }
        }
      }

      // Moon: a crescent, a disc with a second disc of face colour cut out of
      // its upper right.
      Item {
        anchors.fill: parent
        visible: dayMark.night

        Rectangle {
          x: parent.width * 0.18
          y: (parent.height - height) / 2
          width: parent.width * 0.62
          height: width
          radius: width / 2
          color: root.inkColor
        }

        Rectangle {
          x: parent.width * 0.40
          y: parent.height * 0.16
          width: parent.width * 0.56
          height: width
          radius: width / 2
          color: root.faceColor
        }
      }
    }

    // City name where a watch brand would normally sit: between the 12 mark
    // and the centre. Under the hands, so it never hides the time.
    Text {
      id: cityLabel

      anchors.horizontalCenter: parent.horizontalCenter
      y: dial.height * 0.215
      text: root.city
      color: Util.alpha(root.inkColor, 0.9)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: Math.max(0.5, dial.width * 0.006)
    }

    // Date window at three o'clock: the city's own day of the month, cut into
    // the dial. It takes the place of the three o'clock tick and follows the
    // zone, so Tokyo can be a day ahead of Toronto.
    Rectangle {
      id: dateWindow

      width: root.dateWidth
      height: root.dateHeight
      x: root.dateCenterX - width / 2
      y: dial.height / 2 - height / 2
      radius: Math.max(1, dial.width * 0.015)
      color: root.recessColor
      border.width: Math.max(1, Style.space(1))
      border.color: root.recessRimColor

      Text {
        anchors.centerIn: parent
        text: root.day
        color: Util.alpha(root.inkColor, 0.9)
        font.family: Style.font.family
        font.pixelSize: Math.max(7, Math.round(dial.width * 0.115))
        font.bold: true
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
