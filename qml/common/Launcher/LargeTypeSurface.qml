import ".."
import QtQuick

// Ctrl+L shows the search across the whole screen, to read from a distance or
// to show someone. Escape, Ctrl+L, or a click returns to the search unchanged.
FocusScope {
  id: root

  required property var theme
  property string text: ""
  readonly property bool opened: root.text.length > 0
  readonly property alias label: largeText
  signal dismissed()

  visible: root.opened
  enabled: root.opened
  Accessible.role: Accessible.Dialog
  Accessible.name: "Large Type"
  Accessible.description: root.text

  onOpenedChanged: {
    if (root.opened) Qt.callLater(root.forceActiveFocus)
  }

  // Every key stops here: only the ways out do anything.
  Keys.onPressed: event => {
    const control = (event.modifiers & ~Qt.KeypadModifier) === Qt.ControlModifier
    if (event.key === Qt.Key_Escape || (control && event.key === Qt.Key_L)) root.dismissed()
    event.accepted = true
  }

  Rectangle {
    anchors.fill: parent
    color: root.theme.popupBackground
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.dismissed()
  }

  Text {
    id: largeText
    anchors.fill: parent
    anchors.margins: Math.round(48 * root.theme.scale)
    text: root.text
    textFormat: Text.PlainText
    color: root.theme.text
    clip: true
    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    fontSizeMode: Text.Fit
    minimumPixelSize: Math.round(24 * root.theme.scale)
    font.family: root.theme.fontFamily
    font.weight: Font.DemiBold
    font.pixelSize: Math.max(minimumPixelSize, Math.round(root.height * 0.5))
  }
}
