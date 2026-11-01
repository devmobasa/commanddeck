import ".."
import QtQuick
import QtTest
import "../../../qml/common/Protocol.js" as Protocol
import "../../../qml/common/UiConstants.js" as Ui
import "../../../qml/common/Settings/KeyChords.js" as KeyChords

EventPathFixture {
  id: scene

  readonly property var bindings: [
    { chord: "Super+Space", description: "CommandDeck", submap: "" },
    { chord: "Super+Space", description: "Omarchy menu", submap: "" },
    { chord: "Super+Shift+O", description: "Obsidian", submap: "" },
    { chord: "XF86AudioMute", description: "Mute", submap: "" },
    { chord: "Enter", description: "Capture highlighted window", submap: "capture" }
  ]

  EventPathTestCase {
    fixture: scene
    name: "CommandDeck_settings_keybindings"

    function cleanup() {
      const panel = fixture.part_settingsPanel
      panel.part_settingsSearch.text = ""
      panel.showPage(Ui.SettingsPage.Search)
    }

    function test_chords_parse_in_any_order_and_spelling_data() {
      return [
        { tag: "plus", text: "super+space", chord: "super+space" },
        { tag: "spaces", text: "Ctrl K", chord: "ctrl+k" },
        { tag: "order", text: "shift super b", chord: "super+shift+b" },
        { tag: "aliases", text: "win return", chord: "super+enter" },
        { tag: "words", text: "screenshot", chord: "" },
        { tag: "modifier only", text: "super", chord: "" },
        { tag: "two keys", text: "super a b", chord: "" }
      ]
    }

    function test_chords_parse_in_any_order_and_spelling(data) {
      compare(KeyChords.parse(data.text), data.chord)
    }

    function test_search_lists_every_binding_on_a_key() {
      const shared = KeyChords.search(scene.bindings, "SUPER + space")
      compare(shared.rows.length, 2)
      compare(KeyChords.heading(shared, "SUPER + space"), "Super+Space: 2 bindings share this key. Hyprland runs all of them.")
      compare(KeyChords.heading(KeyChords.search(scene.bindings, "super o"), "super o"), "Nothing is bound to super o.")
      compare(KeyChords.search(scene.bindings, "obsidian").rows[0].chord, "Super+Shift+O")
      compare(KeyChords.sharedCounts(scene.bindings)["super+space"], 2)
      compare(KeyChords.sharedCounts(scene.bindings)["enter"], undefined, "a submap binding does not share a top-level key")
    }

    function test_shortcuts_page_finds_a_key_and_its_conflict() {
      const panel = fixture.part_settingsPanel
      panel.snapshot = Object.assign({}, panel.snapshot, { keybindings: scene.bindings })
      panel.visible = true
      waitForValue(panel.searchControl, "activeFocus", true)
      panel.showPage(Ui.SettingsPage.Shortcuts)
      const field = findChild(panel, "keybindingSearch")
      verify(field.visible)
      field.forceActiveFocus()
      tryVerify(() => field.activeFocus, 2000)
      typeText("super+space")
      const heading = findChild(panel, "keybindingHeading")
      tryCompare(heading, "text", "Super+Space: 2 bindings share this key. Hyprland runs all of them.")
      const results = panel.parts.shortcutsScroll.part_keybindingResults
      compare(results.count, 2)
      for (let index = 0; index < results.count; index++) {
        verify(results.itemAt(index).Accessible.name.indexOf("Super+Space:") === 0)
      }
      field.text = "mute"
      tryCompare(heading, "text", "1 binding")
      field.text = ""
    }
  }
}
