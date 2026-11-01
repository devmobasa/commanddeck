import "../.."
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../../TabFence.js" as TabFence

// Stepper for small integers with a unit suffix. Same SpinBox contract
// (`value`, `from`, `to`, `valueModified`).
SpinBox {
  id: root

  required property var theme
  function tint(value, amount) { return Qt.rgba(value.r, value.g, value.b, amount) }
  property string suffix: ""

  // Tab and Shift+Tab stay inside the settings dialog.
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: event => TabFence.route(root.parent, event)

  implicitHeight: Math.round(root.theme.fontBody * 2.1)
  implicitWidth: Math.round(root.theme.fontBody * 4.5) + suffixLabel.implicitWidth + (root.suffix.length > 0 ? Math.round(6 * root.theme.scale) : 0)
  editable: true
  wheelEnabled: true
  hoverEnabled: true
  focusPolicy: Qt.StrongFocus
  leftPadding: Math.round(6 * root.theme.scale)
  rightPadding: root.up.indicator.width + suffixLabel.width + Math.round(6 * root.theme.scale)

  textFromValue: function(value, locale) {
    return String(value)
  }
  valueFromText: function(text, locale) {
    const digits = String(text).replace(/[^0-9]/g, "")
    return digits.length > 0 ? Number(digits) : root.value
  }

  contentItem: TextInput {
    // While editing, this field has focus and would move Tab along Qt's focus
    // chain itself before the spin box saw the key.
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => TabFence.route(root.parent, event)

    text: root.displayText
    color: root.enabled ? root.theme.text : root.theme.textFaint
    horizontalAlignment: Qt.AlignRight
    verticalAlignment: Qt.AlignVCenter
    readOnly: !root.editable
    validator: root.validator
    inputMethodHints: Qt.ImhDigitsOnly
    selectByMouse: true
    font.family: root.theme.monoFontFamily
    font.pixelSize: root.theme.fontBody
    font.weight: Font.Normal
  }

  Text {
    id: suffixLabel
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    text: root.suffix
    color: root.theme.textMuted
    font.family: root.theme.fontFamily
    font.pixelSize: root.theme.fontBody
  }
  component StepButton: Rectangle {
    property bool pressedState: false
    property bool hoveredState: false
    property bool upward: true
    width: Math.round(root.theme.fontBody * 1.3)
    height: root.height / 2
    color: pressedState || hoveredState ? root.theme.surfaceStrong : "transparent"
    radius: Math.round(3 * root.theme.scale)
    Canvas {
      anchors.centerIn: parent
      width: Math.round(8 * root.theme.scale)
      height: Math.round(5 * root.theme.scale)
      readonly property bool upward: parent.upward
      readonly property color ink: root.theme.textMuted
      onInkChanged: requestPaint()
      onUpwardChanged: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = ink
        ctx.lineWidth = 1.5
        ctx.beginPath()
        ctx.moveTo(1, upward ? height - 1 : 1)
        ctx.lineTo(width / 2, upward ? 1 : height - 1)
        ctx.lineTo(width - 1, upward ? height - 1 : 1)
        ctx.stroke()
      }
    }
  }
  up.indicator: StepButton {
    x: root.width - width - suffixLabel.width - (root.suffix.length > 0 ? Math.round(6 * root.theme.scale) : 0)
    y: 0
    upward: true
    pressedState: root.up.pressed
    hoveredState: root.up.hovered
  }
  down.indicator: StepButton {
    x: root.up.indicator.x
    y: root.height / 2
    upward: false
    pressedState: root.down.pressed
    hoveredState: root.down.hovered
  }
  background: Rectangle {
    width: root.width - suffixLabel.width - (root.suffix.length > 0 ? Math.round(6 * root.theme.scale) : 0)
    radius: Math.round(6 * root.theme.scale)
    color: root.theme.surfaceStrong
    border.width: root.activeFocus ? 2 : 1
    border.color: root.activeFocus ? root.theme.focusRing : root.theme.separator
  }
}
