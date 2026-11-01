import ".."
import QtQuick
import Quickshell.Io

// Like the other display stores, this is QML-only and disabled in testMode.
QtObject {
  id: root
  property bool active: true
  property string stateDir: ""
  property string fileName: "interface-font"
  readonly property string filePath: root.stateDir.length > 0 ? root.stateDir + "/" + root.fileName : ""
  property string choice: "sans"
  signal changed()

  function normalize(value) { return String(value).trim() === "shell" ? "shell" : "sans" }
  function load() {
    let saved = ""
    if (root.active && root.filePath.length > 0) {
      try {
        file.waitForJob()
        file.reload()
        file.waitForJob()
        saved = file.text()
      } catch (error) { saved = "" }
    }
    root.choice = root.normalize(saved)
    root.changed()
  }
  function set(value) {
    root.choice = root.normalize(value)
    root.changed()
    if (!root.active || root.filePath.length === 0) return
    try { file.setText(root.choice + "\n") } catch (error) {
      // Match the display stores: apply for this session if saving fails.
    }
  }
  property FileView file: FileView {
    path: root.active ? root.filePath : ""
    blockLoading: true
    printErrors: false
    atomicWrites: true
  }
}
