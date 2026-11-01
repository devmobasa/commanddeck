import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Protocol.js" as Protocol

ColumnLayout {
  id: root
  required property var theme
  property var preferences: null
  property bool busy: false
  property string saveError: ""
  property bool submitted: false
  onSaveErrorChanged: { if (submitted && saveError) row.localError = saveError }
  onBusyChanged: { if (!busy && submitted) { if (saveError) row.localError = saveError; submitted = false } }
  property var savedSearches: []
  readonly property bool settingsRow: true
  readonly property string savedChord: preferences && preferences.clipboardHistoryShortcut !== undefined
    ? preferences.clipboardHistoryShortcut : Protocol.ClipboardShortcut.Default
  readonly property bool conflict: savedSearches.some(search => Boolean(search.shortcut)
    && String(search.shortcut).toUpperCase() === savedChord.toUpperCase())
  readonly property alias pill: row.pill
  readonly property alias shortcutRow: row
  signal saved(var preferences)

  function save(chord) {
    if (!preferences || busy) return
    const value = String(chord).toUpperCase()
    if (value && (!/^CTRL\+(SHIFT|ALT)\+[A-Z]$/.test(value) || value === Protocol.ClipboardShortcut.ReservedCopyChord)) {
      row.localError = "Use Ctrl+Shift+letter or Ctrl+Alt+letter; Ctrl+Shift+C is reserved for copying file paths."
      return
    }
    row.localError = ""
    const next = JSON.parse(JSON.stringify(preferences))
    next.clipboardHistoryShortcut = value
    submitted = true
    saved(next)
  }
  SettingsShortcutRow {
    id: row
    theme: root.theme
    globalShortcut: false
    busy: root.busy && root.submitted
    enabled: !root.busy && root.preferences !== null
    binding: ({ id: "clipboard", description: "Open Clipboard History", chord: root.savedChord, changeable: true })
    warning: root.conflict ? "A saved search already uses this chord. Clipboard's shortcut is inactive until you change or disable it." : ""
    onRecorded: value => root.save(value)
    onRemoveConfirmed: root.save("")
  }
}
