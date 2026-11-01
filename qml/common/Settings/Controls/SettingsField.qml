import "../.."
import QtQuick
import QtQuick.Controls
import "../../TabFence.js" as TabFence

// Single-line text input in the launcher palette.
TextField {
  id: root

  required property var theme
  property bool search: false
  property bool machineText: false

  // Tab and Shift+Tab stay inside the settings dialog.
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: event => TabFence.route(root.parent, event)

  implicitHeight: Math.round(root.theme.fontBody * 2.3)
  leftPadding: Math.round((root.search ? 30 : 12) * root.theme.scale)
  rightPadding: Math.round((root.search && root.text.length > 0 ? 30 : 12) * root.theme.scale)
  color: root.enabled ? root.theme.text : root.theme.textFaint
  placeholderTextColor: root.theme.textFaint
  selectByMouse: true
  hoverEnabled: true
  font.family: root.machineText ? root.theme.monoFontFamily : root.theme.fontFamily
  font.pixelSize: root.theme.fontBody

  SettingsSymbol {
    x: Math.round(10 * root.theme.scale)
    anchors.verticalCenter: parent.verticalCenter
    width: Math.round(13 * root.theme.scale)
    height: width
    visible: root.search
    symbol: "search"
    ink: root.theme.textMuted
  }
  KeyboardButton {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: root.height
    height: root.height
    visible: root.search && root.text.length > 0
    focusPolicy: Qt.NoFocus
    text: "×"
    Accessible.name: "Clear search"
    contentItem: Text {
      text: "×"
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      color: root.theme.textMuted
      font.family: root.theme.fontFamily
      font.pixelSize: root.theme.fontBody
    }
    background: Item {}
    onClicked: { root.clear(); root.forceActiveFocus() }
  }
  background: Rectangle {
    radius: Math.min(root.theme.radius, Math.round(8 * root.theme.scale))
    color: root.theme.withAlpha(root.theme.text, root.search ? 0.07 : 0.06)
    border.width: root.search ? (root.activeFocus ? 1 : 0) : (root.activeFocus ? 2 : 1)
    border.color: root.activeFocus ? root.theme.withAlpha(root.theme.focusRing, root.search ? 0.6 : 1) : root.theme.withAlpha(root.theme.text, 0.10)
  }
}
