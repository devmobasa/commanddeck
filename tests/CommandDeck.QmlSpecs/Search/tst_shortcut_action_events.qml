import ".."
import "../../../qml/common" as Deck
import QtQuick
import QtTest
import "../../../qml/common/Protocol.js" as Protocol
import "../../../qml/common/Launcher/Actions/DeckInvocationActions.js" as Invocation

EventPathFixture {
  id: scene
  SignalSpy { id: requested; target: scene.part_searchField; signalName: "changeShortcutRequested" }
  QtObject {
    id: launcher
    property var part_invocationController: ({busy: false, collecting: false})
    property var part_searchSession: ({canActivate: () => true})
    property bool daemonAvailable: true
    property bool reconciliationPending: false
    property bool actionPanelOpen: true
    property string pendingSettingId: ""
    property string pendingSettingUrl: ""
    property var pendingShortcut: null
    property int opens: 0
    function openSettings() { opens++ }
  }
  Deck.ActionPanel { id: menu; theme: scene.part_searchField.theme; width: 600; height: 300 }
  SignalSpy { id: chosen; target: menu; signalName: "actionChosen" }
  EventPathTestCase {
    fixture: scene
    name: "CommandDeck_shortcut_action"
    function test_alt_k_requests_shortcut_editor_without_opening_actions() {
      fixture.part_searchField.inputControl.forceActiveFocus()
      requested.clear()
      keyClick(Qt.Key_K, Qt.AltModifier)
      compare(requested.count, 1)
      keyClick(Qt.Key_K, Qt.ControlModifier | Qt.ShiftModifier)
      compare(requested.count, 1)
      keyClick(Qt.Key_K, Qt.ControlModifier)
      compare(requested.count, 1)
    }
    function test_action_menu_shows_and_runs_alt_k() {
      menu.result = {id: "demo", title: "Demo", actions: [{id: "change-shortcut", title: "Change Shortcut…", kind: Protocol.ActionKinds.OpenSettings}]}
      waitForFrame(menu)
      function hasHint(item) {
        if (item.text === "Alt+K") return true
        for (const child of item.children || []) if (hasHint(child)) return true
        return false
      }
      verify(hasHint(menu))
      chosen.clear()
      menu.filterControl.forceActiveFocus()
      keyClick(Qt.Key_K, Qt.AltModifier)
      compare(chosen.count, 1)
      compare(chosen.signalArguments[0][0].id, "change-shortcut")
      menu.result = null
    }
    function test_change_and_add_actions_reveal_the_shortcuts_setting_data() {
      return [{tag: "change", chord: "Super+T", command: ""}, {tag: "add", chord: "", command: "fictional-terminal"}]
    }
    function test_change_and_add_actions_reveal_the_shortcuts_setting(data) {
      launcher.opens = 0
      const arguments = ({})
      arguments[Protocol.ActionArgumentNames.SettingId] = Protocol.SettingIds.DesktopShortcuts
      arguments[Protocol.ActionArgumentNames.ShortcutId] = "added:terminal"
      arguments[Protocol.ActionArgumentNames.ShortcutDescription] = "Terminal"
      arguments[Protocol.ActionArgumentNames.ShortcutChord] = data.chord
      arguments[Protocol.ActionArgumentNames.ShortcutCommand] = data.command
      Invocation.invokeAction(launcher, {id: "terminal"}, {kind: Protocol.ActionKinds.OpenSettings, arguments: arguments}, false)
      compare(launcher.opens, 1)
      compare(launcher.pendingSettingId, Protocol.SettingIds.DesktopShortcuts)
      compare(launcher.pendingShortcut.description, "Terminal")
      compare(launcher.pendingShortcut.chord, data.chord)
      compare(launcher.pendingShortcut.command, data.command)
      verify(!launcher.actionPanelOpen)
    }
  }
}
