import Quickshell.Hyprland

// The recording submap resets itself before notifying the focused editor.
// qmllint disable unresolved-type
GlobalShortcut {
  required property var launcher
  appid: "commanddeck"
  name: "record-cancel"
  description: "Cancel shortcut recording"
  onPressed: launcher.part_shortcutEditor.cancelRecording()
}
