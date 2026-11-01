import QtQuick
import "TabFence.js" as TabFence
import "UiConstants.js" as Ui
import QtQuick.Controls

// The CommandDeck button. `kind` is primary, secondary, or danger; `compact`
// shrinks it for dense rows; `flat` hides the idle chrome (icon buttons) while
// keeping the same hover and focus emphasis as every other button.
KeyboardButton {
  id: root

  required property var theme
  function tint(value, amount) { return Qt.rgba(value.r, value.g, value.b, amount) }
  property string kind: Ui.ButtonVariant.Secondary
  property bool compact: false
  // Surfaces that own their own focus cycling (the assistant conversation)
  // turn the settings tab fence off.
  property bool tabFence: true

  // Tab and Shift+Tab stay inside the settings dialog.
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: event => {
    if (root.tabFence) TabFence.route(root.parent, event)
  }

  readonly property bool primary: root.kind === Ui.ButtonVariant.Primary
  readonly property bool dangerous: root.kind === Ui.ButtonVariant.Danger

  implicitHeight: Math.round(root.theme.fontBody * 2.1)
  implicitWidth: Math.max(
    contentText.implicitWidth + Math.round(24 * root.theme.scale),
    implicitHeight)
  leftPadding: Math.round(12 * root.theme.scale)
  rightPadding: leftPadding
  hoverEnabled: true
  focusPolicy: Qt.StrongFocus

  contentItem: Text {
    id: contentText
    text: root.text
    // Titles can come from extensions and the assistant; show them as written.
    textFormat: Text.PlainText
    color: root.primary ? root.theme.accentText
      : !root.enabled ? root.theme.textFaint
      : root.dangerous ? root.theme.urgent
      : root.theme.text
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    // No elide: settings buttons carry short labels and their rows can give them
    // the width. Eliding collapses the button's implicitWidth in a tight layout
    // and truncates the label ("Sign out" -> "Sign o…"), same as AgentButton.
    font.family: root.theme.fontFamily
    font.pixelSize: root.theme.fontBody
    font.weight: Font.Normal
  }

  // Pointer hover changes the pill fill; keyboard focus adds an outer ring.
  readonly property bool emphasized: root.enabled && (root.hovered || root.activeFocus)
  readonly property bool focusRingVisible: root.activeFocus

  background: Rectangle {
    radius: root.theme.radius > 0 ? height / 2 : 0
    color: root.flat && !root.hovered && !root.down ? "transparent"
      : root.primary ? root.theme.accent
      : root.down ? root.tint(root.theme.text, 0.18)
      : root.hovered ? root.tint(root.theme.text, 0.14)
      : root.theme.surfaceStrong
    border.width: 0
    border.color: root.emphasized
      ? root.theme.text
      : root.primary ? root.theme.accent
      : root.dangerous ? root.tint(root.theme.urgent, 0.4)
      : root.theme.separator

    Rectangle {
      anchors.fill: parent
      anchors.margins: -2
      visible: root.focusRingVisible
      color: "transparent"
      radius: parent.radius + Math.round(4 * root.theme.scale)
      border.width: 2
      border.color: root.dangerous ? root.theme.urgent : root.theme.focusRing
    }
  }
}
