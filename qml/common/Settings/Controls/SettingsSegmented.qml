import "../.."
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../TabFence.js" as TabFence

Control {
  id: root
  required property var theme
  property var options: []
  property int currentIndex: 0
  // Section navigation keeps its existing tab stops and explicit activation.
  property bool tabPerSegment: false
  readonly property int count: (root.options || []).length
  readonly property var currentOption: root.currentIndex >= 0 && root.currentIndex < root.count ? root.options[root.currentIndex] : null
  readonly property string currentTitle: root.currentOption ? String(root.currentOption.title || root.currentOption.id) : ""
  readonly property string currentDescription: root.currentOption ? String(root.currentOption.description || "") : ""
  property bool showCurrentDescription: true
  signal activated(int index)
  implicitHeight: Math.round(root.theme.fontBody * 2.1)
  implicitWidth: segments.implicitWidth + padding * 2
  padding: 2
  focusPolicy: root.tabPerSegment ? Qt.NoFocus : Qt.StrongFocus
  Accessible.role: Accessible.Grouping
  readonly property bool segmentFocused: {
    for (let index = 0; index < segmentButtons.count; index++) {
      const button = segmentButtons.itemAt(index)
      if (button && button.activeFocus) return true
    }
    return false
  }

  function focusSegment(index) {
    const button = segmentButtons.itemAt(index)
    if (button) button.forceActiveFocus()
  }
  function optionIndex(id) { return root.options.findIndex(option => String(option.id) === String(id)) }
  function select(index) {
    if (!root.enabled || index < 0 || index >= root.count) return
    root.currentIndex = index
    root.activated(index)
  }
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: event => TabFence.route(root.parent, event)
  Keys.onLeftPressed: root.select(Math.max(0, root.currentIndex - 1))
  Keys.onRightPressed: root.select(Math.min(root.count - 1, root.currentIndex + 1))
  Keys.onSpacePressed: root.select(root.currentIndex)
  Keys.onReturnPressed: root.select(root.currentIndex)

  contentItem: RowLayout {
    id: segments
    spacing: 0
    Repeater {
      id: segmentButtons
      model: root.options
      delegate: RadioButton {
        id: segment
        required property var modelData
        required property int index
        Layout.fillHeight: true
        Layout.fillWidth: true
        implicitWidth: labelText.implicitWidth + Math.round(22 * root.theme.scale)
        padding: 0
        objectName: String(segment.modelData.objectName || "")
        focusPolicy: root.tabPerSegment ? Qt.StrongFocus : Qt.NoFocus
        Keys.priority: Keys.BeforeItem
        Keys.onLeftPressed: root.tabPerSegment ? root.focusSegment(Math.max(0, segment.index - 1)) : root.select(Math.max(0, root.currentIndex - 1))
        Keys.onRightPressed: root.tabPerSegment ? root.focusSegment(Math.min(root.count - 1, segment.index + 1)) : root.select(Math.min(root.count - 1, root.currentIndex + 1))
        Keys.onReturnPressed: root.select(segment.index)
        Keys.onEnterPressed: root.select(segment.index)
        Keys.onPressed: event => TabFence.route(root.parent, event)
        checked: segment.index === root.currentIndex
        text: String(segment.modelData.title || segment.modelData.id)
        Accessible.role: Accessible.RadioButton
        Accessible.checkable: true
        Accessible.checked: checked
        Accessible.name: String(segment.modelData.accessibleName || root.Accessible.name + ": " + text)
        Accessible.description: String(segment.modelData.description || "")
        onClicked: root.select(segment.index)
        indicator: Item {}
        contentItem: Text {
          id: labelText
          text: segment.text
          color: segment.checked ? root.theme.accentText : root.theme.text
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          font.family: root.theme.fontFamily
          font.pixelSize: root.theme.fontBody
          font.weight: segment.checked ? Font.DemiBold : Font.Normal
        }
        background: Rectangle {
          radius: root.theme.radius > 0 ? height / 2 : 0
          color: segment.checked ? root.theme.accent : segment.hovered ? root.theme.surface : "transparent"
          Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: root.theme.radius > 0 ? height / 2 : 0
            visible: root.tabPerSegment && segment.activeFocus
            color: "transparent"
            border.width: 2
            border.color: root.theme.focusRing
          }
        }
      }
    }
  }
  background: Rectangle {
    radius: root.theme.radius > 0 ? height / 2 : 0
    color: root.theme.surfaceStrong
    opacity: root.enabled ? 1 : 0.45
    Rectangle {
      anchors.fill: parent
      anchors.margins: -2
      radius: root.theme.radius > 0 ? height / 2 : 0
      visible: root.activeFocus && !root.segmentFocused
      color: "transparent"
      border.width: 2
      border.color: root.theme.focusRing
    }
  }
}
