import "../.."
import QtQuick
import QtQuick.Controls
import "../../TabFence.js" as TabFence

// A switch that reads as a sentence: the label sits on the left, the pill on
// the right. Keeps the CheckBox contract (`checked`, `toggled`) the panel and
// its specs rely on.
Switch {
  id: root

  required property var theme
  function tint(value, amount) { return Qt.rgba(value.r, value.g, value.b, amount) }
  property string help: ""
  readonly property bool settingsRow: true

  // Tab and Shift+Tab stay inside the settings dialog.
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: event => TabFence.route(root.parent, event)
  Keys.onReturnPressed: event => root.pressFromKeyboard(event)
  Keys.onEnterPressed: event => root.pressFromKeyboard(event)

  // Consume Enter before Qt's platform theme handles it, so it clicks once.
  function pressFromKeyboard(event) {
    if (!event.isAutoRepeat) root.click()
    event.accepted = true
  }

  readonly property int pillWidth: Math.round(root.pillHeight * 1.75)
  readonly property int pillHeight: Math.round(root.theme.fontBody * 1.45)

  implicitHeight: Math.max(Math.round(root.theme.fontBody * 2.75), Math.max(root.pillHeight, labelColumn.implicitHeight) + Math.round(16 * root.theme.scale))
  opacity: root.enabled ? 1 : 0.45
  implicitWidth: labelColumn.implicitWidth + root.pillWidth + spacing
  spacing: Math.round(14 * root.theme.scale)
  hoverEnabled: true
  focusPolicy: Qt.TabFocus

  indicator: Rectangle {
    x: root.width - width
    y: (root.height - height) / 2
    width: root.pillWidth
    height: root.pillHeight
    radius: height / 2
    color: root.checked
      ? root.theme.accent
      : root.tint(root.theme.text, 0.16)
    Rectangle {
      anchors.fill: parent
      anchors.margins: -2
      radius: height / 2
      visible: root.activeFocus
      color: "transparent"
      border.width: 2
      border.color: root.theme.focusRing
    }

    Rectangle {
      x: root.checked ? parent.width - width - 2 : 2
      y: 2
      width: parent.height - 4
      height: width
      radius: width / 2
      color: root.checked ? "#f7f9fc" : root.tint(root.theme.text, 0.85)
      Behavior on x { NumberAnimation { duration: root.theme.durationFast !== undefined ? root.theme.durationFast : 90 } }
    }
  }

  // The control stretches its content item to the full available height, so
  // the label column sits inside a plain Item and centres itself in it.
  contentItem: Item {
    anchors.left: parent.left
    anchors.right: root.indicator.left
    anchors.rightMargin: root.spacing

    Column {
      id: labelColumn
      width: parent.width
      anchors.verticalCenter: parent.verticalCenter
      spacing: Math.round(2 * root.theme.scale)

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: root.text
        color: root.enabled ? root.theme.text : root.theme.textFaint
        wrapMode: Text.Wrap
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontBody
        font.weight: Font.Normal
      }

      Text {
        width: parent.width
        visible: root.help.length > 0
        textFormat: Text.PlainText
        text: root.help
        color: root.theme.textMuted
        wrapMode: Text.Wrap
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSmall
      }
    }
  }

  background: Item {}
}
