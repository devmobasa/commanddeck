import ".."
import QtQuick
import QtTest
import "../../../qml/common" as Deck
import "../../../qml/common/Protocol.js" as Protocol

EventPathFixture {
  id: scene
  QtObject { id: sharedFont; property string choice: "sans" }
  Component {
    id: panelFactory
    Deck.SettingsPanel {
      width: 900; height: 600
      theme: scene.part_theme
      interfaceFont: sharedFont.choice
      onInterfaceFontSelected: choice => sharedFont.choice = choice
    }
  }
  Deck.Theme {
    id: liveTheme
    loadShellTokens: false
    overrideHostColors: true
    deckColors: ({ accent: "#8ab4f8", background: "#10131a", text: "#ff4040" })
  }
  Item {
    id: drawings
    visible: false
    z: 100
    width: 300; height: 80
    Deck.SettingsNumber { id: paintedNumber; theme: liveTheme; value: 42 }
    Deck.SettingsChoice {
      id: paintedChoice
      x: 95; width: 150
      theme: liveTheme
      options: [{ id: "one", title: "One" }]
    }
    Deck.SettingsSymbol { id: paintedSymbol; x: 260; width: 24; height: 24; ink: liveTheme.text }
  }

  EventPathTestCase {
    fixture: scene
    name: "CommandDeck_settings_review"

    function test_two_panels_follow_shared_font_after_both_have_been_used() {
      sharedFont.choice = "sans"
      const first = createTemporaryObject(panelFactory, scene)
      const second = createTemporaryObject(panelFactory, scene)
      verify(first && second)
      first.visible = true
      first.searchControl.text = "interface font"
      second.searchControl.text = "interface font"
      second.visible = false
      waitForFrame(first)
      const firstChoice = first.part_interfaceFont
      const secondChoice = second.part_interfaceFont
      mouseClick(firstChoice, firstChoice.width * 0.8, firstChoice.height / 2)
      compare(sharedFont.choice, "shell")
      compare(secondChoice.currentIndex, 1)
      first.visible = false
      second.visible = true
      waitForFrame(second)
      mouseClick(secondChoice, secondChoice.width * 0.2, secondChoice.height / 2)
      compare(sharedFont.choice, "sans")
      compare(firstChoice.currentIndex, 0, "a used panel follows a change from another monitor")
      first.visible = true
      second.visible = false
      waitForFrame(first)
      mouseClick(firstChoice, firstChoice.width * 0.8, firstChoice.height / 2)
      compare(secondChoice.currentIndex, 1, "both used controls keep following the shared preference")
    }

    function test_tab_from_clicked_number_editor_reaches_close() {
      const panel = fixture.part_settingsPanel
      panel.visible = true
      waitForValue(panel.searchControl, "activeFocus", true)
      panel.searchControl.text = "turn timeout"
      waitForFrame(panel)
      const number = panel.agentTurnTimeoutControl
      number.forceActiveFocus()
      waitForFrame(number)
      mouseClick(number.contentItem, number.contentItem.width / 2, number.contentItem.height / 2)
      verify(number.contentItem.activeFocus, "the actual inner number editor has pointer focus")
      keyClick(Qt.Key_Tab)
      verify(panel.closeControl.activeFocus, "Tab from the final control's editor reaches Close")
      keyClick(Qt.Key_Backtab)
      verify(number.activeFocus || number.contentItem.activeFocus)
    }

    function test_section_focus_ring_moves_without_changing_selection() {
      const panel = fixture.part_settingsPanel
      panel.visible = true
      panel.showPage("assistant")
      waitForFrame(panel)
      const assistant = findChild(panel, "aiAssistantSection")
      const quick = findChild(panel, "aiQuickSection")
      verify(assistant && quick)
      assistant.forceActiveFocus()
      const switcher = assistant.parent.parent
      verify(assistant.background.children[0].visible)
      verify(!switcher.background.children[0].visible, "child focus uses a segment ring")
      keyClick(Qt.Key_Right)
      verify(quick.activeFocus)
      verify(assistant.checked && !quick.checked, "arrow focus alone does not activate a section")
      verify(!assistant.background.children[0].visible)
      verify(quick.background.children[0].visible)
      compare(quick.background.children[0].border.color, panel.theme.focusRing)
    }

    function test_closed_trust_duration_keeps_description_and_persistent_warning() {
      const panel = fixture.part_settingsPanel
      panel.visible = true
      panel.showPage("assistant")
      panel.agentChallenge = { id: "review", targetLevel: 6, requiresPhrase: true,
        requiresDuration: true, prompt: "Confirm unrestricted authority", warnings: [] }
      waitForFrame(panel)
      const choice = panel.agentDurationControl
      const row = choice.parent.parent.parent
      compare(row.label, "Trust duration")
      compare(row.Accessible.name, "Trust duration")
      choice.currentIndex = 1
      verify(!choice.popup.visible)
      const warning = findChild(row, "settingsChoiceWarning")
      verify(warning && warning.visible)
      compare(warning.text, "Persistent")
      compare(warning.color, panel.theme.urgent)
      const labels = row.children[0].children[0].children
      verify(labels.some(item => item.text && item.text.indexOf("Stays unrestricted until you lower the level.") >= 0))
      choice.currentIndex = 0
      verify(!warning.visible)
      verify(labels.some(item => item.text && item.text.indexOf("Authority lapses on its own.") >= 0))
      const accountRows = panel.part_assistantCard.body.filter(item => item.settingsRow && item.label)
      compare(accountRows[0].label, "Sign-in status")
      compare(accountRows[0].Accessible.name, "Sign-in status")
    }

    function coloredPixels(item, green) {
      const pixels = grabImage(scene)
      const origin = item.mapToItem(scene, 0, 0)
      let count = 0
      for (let y = 0; y < item.height; y++) {
        for (let x = 0; x < item.width; x++) {
          const pixel = pixels.pixel(Math.floor(origin.x + x), Math.floor(origin.y + y))
          if (green ? pixel.g > pixel.r * 1.7 : pixel.r > pixel.g * 1.7) count++
        }
      }
      return count
    }

    function test_canvas_ink_repaints_after_palette_change() {
      fixture.part_settingsPanel.visible = false
      drawings.visible = true
      const canvases = [paintedNumber.up.indicator.children[0], paintedNumber.down.indicator.children[0],
        paintedChoice.indicator.children[0], paintedSymbol]
      try {
        liveTheme.deckColors = { accent: "#8ab4f8", background: "#10131a", text: "#ff4040" }
        for (const canvas of canvases) {
          waitForFrame(canvas)
          verify(coloredPixels(canvas, false) >= 4, "the initial red ink is painted")
        }
        liveTheme.deckColors = { accent: "#8ab4f8", background: "#10131a", text: "#40ff40" }
        for (const canvas of canvases) {
          waitForFrame(canvas)
          verify(coloredPixels(canvas, true) >= 4, "the palette change repaints the glyph green")
          compare(coloredPixels(canvas, false), 0, "no stale red pixels remain")
        }
      } finally { drawings.visible = false }
    }
  }
}
