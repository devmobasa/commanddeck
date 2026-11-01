pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

// Each capture isolates a real Settings card using the Settings search field.
ShellRoot {
  DemoStage {
    id: stage
    shots: ["display", "layout", "search", "folders", "quicklinks", "quicklink-edit", "customization", "ai", "trust-duration", "quick-answers", "editors", "filters", "shortcuts", "shortcuts-preparing", "shortcuts-recording", "shortcuts-conflict", "shortcuts-remove", "shortcuts-error", "shortcuts-changed", "shortcuts-readonly", "shortcuts-menu", "diagnostics", "overview", "limits", "choices", "font-shell", "narrow"].map(function(section) {
      return {
        name: "settings-" + section + ".png",
        frame: { width: section === "narrow" ? 640 : 1280, height: 900 },
        show: function() { gallerySettings.show(section) }
      }
    })
    onShotSaved: name => {
      if (!gallerySettings.verify(name.slice("settings-".length, -".png".length))) Qt.exit(1)
    }
    panelOverlays: [
      DemoSettings {
        id: gallerySettings
        galleryStage: stage
        anchors.fill: parent
      }
    ]
  }
}
