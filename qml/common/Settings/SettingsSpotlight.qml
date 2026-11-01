import ".."
import QtQuick

// Points at one Settings card after the launcher opened it there: the card
// scrolls into view, the rest of the panel dims around it, and the dim fades.
// It takes no input, so the page stays usable the whole time.
Item {
  id: root

  required property var theme
  property var target: null
  property rect area: Qt.rect(0, 0, 0, 0)
  readonly property color scrim: Qt.rgba(0, 0, 0, 0.6)
  readonly property int margin: Math.round(12 * root.theme.scale)
  readonly property bool active: root.opacity > 0

  opacity: 0
  visible: root.active
  enabled: false

  function reveal(card) {
    if (!card || !card.visible) return false
    root.target = card
    root.scrollIntoView(card)
    Qt.callLater(root.show)
    return true
  }

  // The nearest scrolling ancestor brings the card's top into view.
  function scrollIntoView(card) {
    for (let item = card.parent; item; item = item.parent) {
      if (item.contentY === undefined || item.contentHeight === undefined || !item.contentItem) continue
      const top = card.mapToItem(item.contentItem, 0, 0).y
      const limit = Math.max(0, item.contentHeight - item.height)
      item.contentY = Math.max(0, Math.min(limit, top - root.margin))
      return
    }
  }

  // Lifts the dim at once, as when the search changes under it.
  function dismiss() {
    fade.stop()
    still.stop()
    root.opacity = 0
  }

  function show() {
    if (!root.target) return
    const point = root.target.mapToItem(root, 0, 0)
    root.area = Qt.rect(point.x, point.y, root.target.width, root.target.height)
    fade.stop()
    still.stop()
    if (root.theme.reduceMotion) {
      root.opacity = 1
      still.restart()
    } else {
      fade.restart()
    }
  }

  SequentialAnimation {
    id: fade
    NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
    PauseAnimation { duration: 2000 }
    NumberAnimation { target: root; property: "opacity"; to: 0; duration: 500; easing.type: Easing.InOutQuad }
  }

  // Reduced motion shows the outline without fading, then removes it.
  Timer {
    id: still
    interval: 2500
    onTriggered: root.opacity = 0
  }

  // Four panes around the card dim the rest of the panel.
  Rectangle { x: 0; y: 0; width: root.width; height: Math.max(0, root.area.y); color: root.scrim }
  Rectangle {
    x: 0
    y: root.area.y + root.area.height
    width: root.width
    height: Math.max(0, root.height - y)
    color: root.scrim
  }
  Rectangle { x: 0; y: root.area.y; width: Math.max(0, root.area.x); height: root.area.height; color: root.scrim }
  Rectangle {
    x: root.area.x + root.area.width
    y: root.area.y
    width: Math.max(0, root.width - x)
    height: root.area.height
    color: root.scrim
  }

  Rectangle {
    id: outline
    readonly property int line: Math.max(2, Math.round(2 * root.theme.scale))
    x: root.area.x - outline.line
    y: root.area.y - outline.line
    width: root.area.width + outline.line * 2
    height: root.area.height + outline.line * 2
    radius: root.theme.radius + outline.line
    color: "transparent"
    border.width: outline.line
    border.color: root.theme.accent
  }
}
