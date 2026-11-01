import ".."
import QtQuick
import QtTest
import "../../../qml/common/UiConstants.js" as Ui
import "../../../qml/common/Settings/Actions/SettingsNavigationActions.js" as Navigation

// Home and End go to the top or bottom of a Settings page from the keyboard:
// the empty search scrolls the page, a control on the page moves focus to the
// first or last control, and the rail picks the first or last page.
EventPathFixture {
  id: scene

  EventPathTestCase {
    fixture: scene
    name: "CommandDeck_settings_home_end"

    function focused() { return fixture.part_settingsPanel.Window.window.activeFocusItem }

    function openCustomization() {
      const panel = fixture.part_settingsPanel
      panel.part_settingsSearch.text = ""
      panel.showPage(Ui.SettingsPage.Customization)
      panel.visible = true
      waitForValue(panel.searchControl, "activeFocus", true)
      wait(0) // Settings focuses its search once more after it shows.
      const flick = panel.parts.customizationScroll.contentItem
      flick.contentY = 0
      return flick
    }

    function bottomOf(flick) { return flick.originY + Math.max(0, flick.contentHeight - flick.height) }

    function cleanup() {
      const panel = fixture.part_settingsPanel
      panel.part_settingsSearch.text = ""
      panel.showPage(Ui.SettingsPage.Search)
    }

    function test_empty_search_scrolls_the_page_and_keeps_typing_focus() {
      const panel = fixture.part_settingsPanel
      const flick = openCustomization()
      verify(bottomOf(flick) > flick.originY, "the page is long enough to scroll")

      keyClick(Qt.Key_End)
      compare(flick.contentY, bottomOf(flick))
      verify(panel.searchControl.activeFocus, "typing still searches")
      keyClick(Qt.Key_Home)
      compare(flick.contentY, flick.originY)
      verify(panel.searchControl.activeFocus)
    }

    function test_search_text_keeps_home_and_end_for_its_cursor() {
      const panel = fixture.part_settingsPanel
      const flick = openCustomization()
      typeText("size")
      flick.contentY = 0
      keyClick(Qt.Key_End)
      compare(flick.contentY, flick.originY, "a typed search keeps End for its cursor")
      verify(panel.searchControl.activeFocus)
    }

    function test_page_controls_jump_to_the_first_and_last_control() {
      const panel = fixture.part_settingsPanel
      const flick = openCustomization()
      panel.part_interfaceFont.forceActiveFocus()
      waitForValue(panel.part_interfaceFont, "activeFocus", true)

      keyClick(Qt.Key_End)
      const last = Navigation.lastContentControl(panel.parts.customizationScroll)
      verify(last !== null && last.activeFocus, "End focuses the last control")
      compare(flick.contentY, bottomOf(flick))

      keyClick(Qt.Key_Home)
      const first = Navigation.firstContentControl(panel.parts.customizationScroll)
      verify(first !== null && first.activeFocus, "Home focuses the first control")
      compare(flick.contentY, flick.originY)
    }

    function test_rail_picks_the_first_and_last_page() {
      const panel = fixture.part_settingsPanel
      openCustomization()
      panel.navigationControl.forceActiveFocus()
      keyClick(Qt.Key_End)
      compare(panel.currentPage, panel.filteredPages[panel.filteredPages.length - 1].id)
      keyClick(Qt.Key_Home)
      compare(panel.currentPage, panel.filteredPages[0].id)
      verify(panel.navigationControl.activeFocus)
    }
  }
}
