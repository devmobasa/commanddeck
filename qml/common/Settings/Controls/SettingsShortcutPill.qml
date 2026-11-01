import "../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "../KeyChords.js" as KeyChords
import "../RecordingKeys.js" as RecordingKeys

AbstractButton {
  id: root
  required property var theme
  property string actionName: ""
  property string chord: ""
  property bool recordable: true
  property bool captureRequired: false
  property bool preparing: false
  property int captureGeneration: 0
  property bool recording: false
  property bool saving: false
  property bool pending: false
  property string proposedChord: ""
  property string pendingChord: ""
  signal recordingStarted()
  signal recordingStopped()
  signal recorded(string value)
  signal removalRequested()
  signal preparationTimedOut()
  // Wide enough for the whole chord (Super+Alt+Shift+Print) up to a cap;
  // shorter chords keep the shared width so pills line up.
  implicitWidth: Math.min(Math.round(theme.fontBody * 20),
    Math.max(Math.round(theme.fontBody * 10), Math.ceil(labelMetrics.advanceWidth) + label.leftPadding + label.rightPadding + 2))
  implicitHeight: Math.round(theme.fontBody * 2.1)
  focusPolicy: Qt.StrongFocus
  enabled: !saving
  hoverEnabled: true
  Accessible.role: Accessible.Button
  Accessible.name: actionName + " shortcut"
  Accessible.description: preparing ? "Preparing shortcut recording." : recording ? "Press the new shortcut. Escape cancels." : pending ? proposedChord : chord || "Not set"
  Accessible.onPressAction: startRecording()

  function startRecording() {
    if (!visible || !enabled || !recordable || saving || recording || preparing) return
    forceActiveFocus()
    pendingChord = ""
    captureGeneration++
    preparing = true
    recordingStarted()
    if (!captureRequired) captureReady()
  }
  function captureReady(expectedGeneration) {
    if (expectedGeneration !== undefined && expectedGeneration !== captureGeneration) return
    if (!preparing) return
    preparing = false
    recording = true
    captureTimeout.restart()
    Accessible.announce("Press the new shortcut. Escape cancels.")
  }
  function cancelRecording() {
    if (!recording && !preparing) return
    preparing = false
    recording = false
    recordingStopped()
  }
  onClicked: startRecording()
  onActiveFocusChanged: { if (!activeFocus) cancelRecording() }
  onVisibleChanged: { if (!visible) cancelRecording() }
  Component.onDestruction: { if (recording || preparing) recordingStopped() }
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: event => {
    if (preparing) {
      if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab || event.key === Qt.Key_Escape) cancelRecording()
      event.accepted = event.key !== Qt.Key_Tab && event.key !== Qt.Key_Backtab
      return
    }
    if (!recording) {
      if (recordable && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
        startRecording()
        event.accepted = true
      }
      return
    }
    if (event.isAutoRepeat) { event.accepted = true; return }
    const modifiers = event.modifiers & (Qt.MetaModifier | Qt.ControlModifier | Qt.AltModifier | Qt.ShiftModifier)
    if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
      cancelRecording()
      event.accepted = false
      return
    }
    event.accepted = true
    if (event.key === Qt.Key_Escape && !modifiers) { cancelRecording(); return }
    if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) && !modifiers) {
      cancelRecording()
      if (chord.length > 0) removalRequested()
      return
    }
    const value = RecordingKeys.chord(event)
    if (!value) return
    pendingChord = value
    cancelRecording()
    recorded(value)
  }
  background: Rectangle {
    radius: root.theme.radius > 0 ? height / 2 : 0
    color: root.chord || root.preparing || root.recording || root.saving || root.pending ? root.theme.withAlpha(root.theme.text, 0.10) : "transparent"
    border.width: root.preparing ? 0 : root.recording ? 2 : root.pending || root.visualFocus ? 1 : 0
    border.color: root.pending && !root.recording ? root.theme.withAlpha(root.theme.focusRing, 0.6) : root.theme.focusRing
  }
  TextMetrics { id: labelMetrics; font: label.font; text: label.text }
  contentItem: Text {
    id: label
    text: root.preparing ? "Preparing…" : root.recording ? "Type Shortcut…" : root.pending ? KeyChords.display(root.proposedChord)
      : root.saving && root.pendingChord ? KeyChords.display(root.pendingChord)
      : root.chord ? KeyChords.display(root.chord) : root.recordable ? "Record Shortcut" : "Not set"
    textFormat: Text.PlainText
    horizontalAlignment: root.recording ? Text.AlignLeft : Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    leftPadding: Math.round((root.recording ? 4 : 8) * root.theme.scale)
    rightPadding: root.recording ? cancelButton.width + root.theme.scale : leftPadding
    color: root.preparing || root.recording || (!root.chord && !root.pending) ? root.theme.textMuted : root.theme.text
    opacity: root.saving ? 0.6 : 1
    font.family: (root.chord || root.pending) && !root.recording && !root.preparing ? root.theme.monoFontFamily : root.theme.fontFamily
    font.pixelSize: root.theme.fontBody
    elide: Text.ElideRight
  }
  ToolButton {
    id: cancelButton
    visible: root.recording || root.preparing
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: Math.round(root.theme.fontBody * 1.7)
    height: root.height
    text: "⊗"
    Accessible.name: "Cancel recording"
    onClicked: root.cancelRecording()
    contentItem: Text { text: cancelButton.text; color: root.theme.textMuted; font.pixelSize: root.theme.fontBody; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    background: Item {}
  }
  Timer {
    id: captureTimeout
    interval: 10000
    running: root.recording || root.preparing
    onTriggered: { if (root.preparing) root.preparationTimedOut(); root.cancelRecording() }
  }
  Connections {
    target: root.Window.window
    function onActiveChanged() { if (!root.Window.window.active) root.cancelRecording() }
  }
  property Item outsideProbe: Item {
    parent: root.Window.window ? root.Window.window.contentItem : null
    anchors.fill: parent
    TapHandler {
      enabled: root.recording || root.preparing
      onPressedChanged: {
        if (!pressed || !parent) return
        const point = root.mapFromItem(parent, this.point.position.x, this.point.position.y)
        if (point.x < 0 || point.y < 0 || point.x > root.width || point.y > root.height) root.cancelRecording()
      }
    }
  }
}
