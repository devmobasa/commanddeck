.pragma library
.import "../Protocol.js" as Protocol

// The Settings cards the launcher can open, generated from Core's SettingsIndex.
function entry(settingId) {
  for (const name in Protocol.SettingsEntries) {
    const value = Protocol.SettingsEntries[name]
    if (value.id === settingId) return value
  }
  return null
}
